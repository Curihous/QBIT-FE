import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:qbit_services/storage/token_service.dart';
import 'package:qbit_services/models/order_model.dart';
import 'package:qbit_services/auth/auth_service.dart';

/// 주문 실시간 체결 상태 WebSocket 서비스
class OrderWebSocketService {
  OrderWebSocketService._internal();
  static final OrderWebSocketService instance = OrderWebSocketService._internal();

  final Logger _logger = Logger();
  final String _wsUrl = 'ws://15.165.205.46:8081/ws/websocket';

  WebSocketChannel? _channel;
  StreamSubscription? _channelSub;
  final StreamController<dynamic> _messageController = StreamController<dynamic>.broadcast();

  bool _connecting = false;
  bool _manuallyClosed = false;
  bool _isAuthenticated = false;
  int _reconnectAttempts = 0;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  Stream<dynamic> get messages => _messageController.stream;

  Future<void> connect() async {
    if (_connecting || _channel != null) return;
    
    // 인증 상태 확인
    final token = await TokenService.getAccessToken();
    if (token == null) {
      _logger.w('인증 토큰이 없어 WebSocket 연결을 건너뜁니다');
      return;
    }
    
    _connecting = true;
    _manuallyClosed = false;

    try {
      _logger.i('WebSocket 연결 시도: $_wsUrl');
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      
      // 수신 스트림 리스닝
      _channelSub = _channel!.stream.listen(
        (event) {
          _logger.d('WebSocket 메시지 수신: $event');
          _handleStompMessage(event);
        },
        onDone: () {
          _logger.i('WebSocket 연결 종료');
          _cleanup();
          if (!_manuallyClosed) _scheduleReconnect();
        },
        onError: (error) {
          _logger.e('WebSocket 에러: $error');
          _cleanup();
          if (!_manuallyClosed) _scheduleReconnect();
        },
        cancelOnError: true,
      );

      _reconnectAttempts = 0;
      // STOMP CONNECT 프레임 송신
      await _sendStompConnect();
      _startHeartbeat();
    } finally {
      _connecting = false;
    }
  }

  void _scheduleReconnect() {
    if (_reconnectTimer?.isActive == true) return;
    
    _reconnectAttempts++;
    final delayMs = (1000 * (_reconnectAttempts.clamp(1, 10))).toInt();
    _logger.i('WebSocket 재연결 시도 $_reconnectAttempts회 (${delayMs}ms 후)');
    
    _reconnectTimer = Timer(Duration(milliseconds: delayMs), () {
      if (_manuallyClosed) return;
      
      // 토큰 상태 재확인 및 갱신 시도
      _refreshTokenAndReconnect();
    });
  }

  Future<void> _refreshTokenAndReconnect() async {
    try {
      // 현재 토큰 확인
      final currentToken = await TokenService.getAccessToken();
      if (currentToken == null) {
        _logger.w('토큰이 없어 재연결을 건너뜁니다');
        return;
      }

      // 토큰 만료 여부 확인 (JWT 디코딩)
      final tokenParts = currentToken.split('.');
      if (tokenParts.length == 3) {
        try {
          final payload = json.decode(utf8.decode(base64Url.decode(base64Url.normalize(tokenParts[1]))));
          final exp = payload['exp'] as int?;
          final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          
          if (exp != null && exp <= now + 60) { // 60초 전에 만료 예정이면 갱신
            _logger.i('토큰이 곧 만료됩니다. 갱신을 시도합니다.');
            await _refreshToken();
          }
        } catch (e) {
          _logger.w('토큰 파싱 실패, 재연결을 시도합니다: $e');
        }
      }

      // 재연결
      await connect();
    } catch (e) {
      _logger.e('토큰 갱신 및 재연결 실패: $e');
    }
  }

  Future<void> _refreshToken() async {
    try {
      // AuthService를 통해 토큰 갱신 시도
      await AuthService.refreshAccessToken();
      _logger.i('토큰 갱신 성공');
    } catch (e) {
      _logger.e('토큰 갱신 실패: $e');
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_channel != null && !_manuallyClosed) {
        _sendHeartbeat();
      } else {
        timer.cancel();
      }
    });
  }

  void _sendHeartbeat() {
    try {
      _channel?.sink.add('\n');
      _logger.d('하트비트 전송');
    } catch (e) {
      _logger.e('하트비트 전송 실패: $e');
    }
  }

  // STOMP 메시지 처리
  Future<void> _handleStompMessage(dynamic event) async {
    if (event is! String) return;
    
    final lines = event.split('\n');
    if (lines.isEmpty) return;
    
    final command = lines[0].trim();
    
    switch (command) {
      case 'CONNECTED':
        _logger.i('STOMP 연결 성공');
        _isAuthenticated = true;
        _reconnectAttempts = 0; // 연결 성공 시 재시도 횟수 리셋
        
        // CONNECTED 후 구독 요청
        await _subscribeToOrders();
        await _subscribeToCycles();
        break;
      case 'ERROR':
        _logger.e('STOMP 에러: ${lines.skip(1).join('\n')}');
        _isAuthenticated = false;
        break;
      case 'MESSAGE':
        _handleStompDataMessage(lines);
        break;
      default:
        _logger.d('STOMP 메시지: $command');
    }
  }

  // STOMP DATA 메시지 처리
  void _handleStompDataMessage(List<String> lines) {
    try {
      // 헤더 파싱
      final headers = <String, String>{};
      int bodyStartIndex = 1;
      
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) {
          bodyStartIndex = i + 1;
          break;
        }
        
        final colonIndex = line.indexOf(':');
        if (colonIndex > 0) {
          final key = line.substring(0, colonIndex).trim();
          final value = line.substring(colonIndex + 1).trim();
          headers[key] = value;
        }
      }
      
      // 본문 파싱
      if (bodyStartIndex < lines.length) {
        final body = lines.skip(bodyStartIndex).join('\n').trim();
        if (body.isNotEmpty) {
          final jsonData = json.decode(body);
          _logger.d('STOMP 데이터 메시지: $jsonData');
          _messageController.add(jsonData);
        }
      }
    } catch (e) {
      _logger.e('STOMP 메시지 파싱 실패: $e');
    }
  }

  void _cleanup() {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _channelSub?.cancel();
    _channelSub = null;
    _channel = null;
    _isAuthenticated = false;
  }

  /// WebSocket 연결 해제
  Future<void> disconnect() async {
    _manuallyClosed = true;
    try {
      await _channel?.sink.close(status.normalClosure);
    } catch (_) {}
    _cleanup();
  }

  // 리소스 정리
  void dispose() {
    _messageController.close();
    _cleanup();
  }

  // 토큰 갱신 후 재연결
  Future<void> reconnectWithNewToken() async {
    _logger.i('새 토큰으로 WebSocket 재연결');
    await disconnect();
    await Future.delayed(const Duration(milliseconds: 1000));
    await connect();
  }

  // --- STOMP helpers ---
  Future<void> _sendStompConnect() async {
    try {
      final token = await TokenService.getAccessToken();
      
      if (token == null) {
        _logger.e('인증 토큰이 없습니다');
        return;
      }
      
      // WebSocket 연결 상태 확인
      if (_channel == null) {
        _logger.e('WebSocket 채널이 연결되지 않았습니다');
        return;
      }
      
      // 토큰 유효성 간단 체크 (JWT 형식 확인)
      if (!token.contains('.')) {
        _logger.e('잘못된 JWT 토큰 형식: $token');
        return;
      }
      
      _logger.i('토큰 확인: ${token.substring(0, 20)}...');
      
      // STOMP 프로토콜 표준에 맞게 CRLF 사용
      final frame = 'CONNECT\r\n'
          'accept-version:1.2\r\n'
          'host:realtime\r\n'
          'Authorization:Bearer $token\r\n'
          'heart-beat:10000,10000\r\n'
          '\r\n'
          '\x00';

      // 디버깅 로그 - 바이트 단위 확인
      final frameBytes = frame.codeUnits;
      _logger.i('STOMP CONNECT 전송 (바이트 길이: ${frameBytes.length}):');
      _logger.i('프레임 내용: ${frame.replaceAll('\x00', '\\x00').replaceAll('\r', '\\r').replaceAll('\n', '\\n')}');
      _logger.i('바이트 배열: ${frameBytes.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' ')}');
      
      _channel?.sink.add(frame);
      
    } catch (e) {
      _logger.e('STOMP CONNECT 전송 실패: $e');
    }
  }

  // 주문 상태 업데이트 구독
  Future<void> _subscribeToOrders() async {
    try {
      final frame = 'SUBSCRIBE\r\n'
          'id:orders-subscription\r\n'
          'destination:/user/queue/orders-updates\r\n'
          '\r\n'
          '\x00';
      _channel?.sink.add(frame);
    } catch (e) {
      _logger.e('STOMP SUBSCRIBE 전송 실패: $e');
    }
  }

  // 사이클 업데이트 구독
  Future<void> _subscribeToCycles() async {
    try {
      final frame = 'SUBSCRIBE\r\n'
          'id:cycles-subscription\r\n'
          'destination:/user/queue/trade-cycles-updates\r\n'
          '\r\n'
          '\x00';
      _channel?.sink.add(frame);
    } catch (e) {
      _logger.e('STOMP 사이클 구독 전송 실패: $e');
    }
  }

  // 주문 상태 업데이트 스트림
  Stream<OrderUpdateMessage> get orderUpdates {
    return messages.where((message) {
      if (message is Map<String, dynamic>) {
        // 주문 업데이트 메시지만 필터링
        return message['type'] == 'order_update';
      }
      return false;
    }).map((message) {
      try {
        return OrderUpdateMessage.fromJson(message as Map<String, dynamic>);
      } catch (e) {
        _logger.e('주문 업데이트 메시지 파싱 실패: $e');
        throw e;
      }
    });
  }

  // TradeCycle 업데이트 스트림
  Stream<TradeCycle> get tradeCycleUpdates {
    return messages.where((message) {
      if (message is Map<String, dynamic>) {
        // 디버깅: 모든 메시지 로그 출력
        _logger.d('수신된 웹소켓 메시지: $message');
        _logger.d('메시지 타입: ${message['type']}');
        _logger.d('메시지 키들: ${message.keys.toList()}');
        
        // TradeCycle 관련 메시지 필터링 (여러 타입 시도)
        final isTradeCycle = message['type'] == 'trade_cycle_update' ||
               message['type'] == 'cycle_update' ||
               message['type'] == 'trade_cycle' ||
               message.containsKey('cycleId') ||
               message.containsKey('tradeCycleId') ||
               message.containsKey('symbol') && message.containsKey('side');
        
        _logger.d('TradeCycle 메시지 여부: $isTradeCycle');
        return isTradeCycle;
      }
      return false;
    }).map((message) {
      try {
        _logger.i('사이클 업데이트 메시지 처리: $message');
        return TradeCycle.fromJson(message as Map<String, dynamic>);
      } catch (e) {
        _logger.e('TradeCycle 메시지 파싱 실패: $e, 메시지: $message');
        throw e;
      }
    });
  }

  // 연결 상태 확인
  bool get isConnected => _channel != null && _isAuthenticated && !_connecting;

  // 연결 상태 스트림
  Stream<bool> get connectionStatus {
    return Stream.periodic(const Duration(seconds: 1))
        .map((_) => isConnected)
        .distinct();
  }

  /// 로그인 시 WebSocket 연결
  Future<void> connectOnLogin() async {
    _logger.i('로그인 후 WebSocket 연결 시도');
    await connect();
  }

  /// 로그아웃 시 WebSocket 연결 해제
  Future<void> disconnectOnLogout() async {
    _logger.i('로그아웃 시 WebSocket 연결 해제');
    await disconnect();
  }
}