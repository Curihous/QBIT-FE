import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:qbit_core/config/env_config.dart';
import 'package:qbit_services/storage/token_service.dart';
import 'package:qbit_services/models/order_model.dart';
import 'package:qbit_services/auth/auth_service.dart';

/// 주문 실시간 체결 상태 WebSocket 서비스
class OrderWebSocketService {
  OrderWebSocketService._internal();
  static final OrderWebSocketService instance = OrderWebSocketService._internal();

  final Logger _logger = Logger();
  
  /// WebSocket URL (환경 변수에서 가져오거나 기본값 사용)
  String get _wsUrl => EnvConfig.websocketUrl;

  WebSocketChannel? _channel;
  StreamSubscription? _channelSub;
  final StreamController<dynamic> _messageController = StreamController<dynamic>.broadcast();

  bool _connecting = false;
  bool _manuallyClosed = false;
  bool _isAuthenticated = false;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  static const int _maxReconnectAttempts = 10; // 최대 재연결 시도 횟수

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
    // 수동 연결 시도 시 재연결 시도 횟수 리셋
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _logger.i('재연결 시도 횟수 리셋 (수동 연결 시도)');
      _reconnectAttempts = 0;
    }

    try {
      _logger.i('WebSocket 연결 시도: $_wsUrl');
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      
      // 수신 스트림 리스닝
      _channelSub = _channel!.stream.listen(
        (event) {
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
      // WebSocket 연결 후 안정화를 위해 잠시 대기
      await Future.delayed(const Duration(milliseconds: 100));
      // STOMP CONNECT 프레임 송신
      await _sendStompConnect();
    } finally {
      _connecting = false;
    }
  }

  void _scheduleReconnect() {
    if (_reconnectTimer?.isActive == true) return;
    
    // 최대 재연결 시도 횟수 초과 시 재연결 중단
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _logger.w('WebSocket 재연결 시도 횟수 초과 (최대 $_maxReconnectAttempts회). 재연결을 중단합니다.');
      _logger.w('서버가 응답하지 않습니다. 잠시 후 수동으로 재연결을 시도해주세요.');
      return;
    }
    
    _reconnectAttempts++;
    final delayMs = (1000 * (_reconnectAttempts.clamp(1, 10))).toInt();
    _logger.i('WebSocket 재연결 시도 $_reconnectAttempts/$_maxReconnectAttempts회 (${delayMs}ms 후)');
    
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

  // STOMP 메시지 처리
  Future<void> _handleStompMessage(dynamic event) async {
    if (event is! String) {
      _logger.w('WebSocket 메시지가 String이 아님: ${event.runtimeType}');
      return;
    }
    
    // 빈 메시지 체크
    if (event.trim().isEmpty) {
      _logger.d('빈 WebSocket 메시지 수신');
      return;
    }
    
    final lines = event.split('\n');
    if (lines.isEmpty) {
      _logger.w('메시지 라인이 비어있음');
      return;
    }
    
    final command = lines[0].trim();
    
    // command가 null이거나 빈 경우 처리
    if (command.isEmpty) {
      return;
    }
    
    switch (command) {
      case 'CONNECTED':
        _logger.i('STOMP 연결 성공');
        _isAuthenticated = true;
        _reconnectAttempts = 0; // 연결 성공 시 재시도 횟수 리셋
        
        // CONNECTED 후 구독 요청
        await _subscribeToOrders();
        break;
      case 'ERROR':
        _logger.e('STOMP 에러: ${lines.skip(1).join('\n')}');
        _isAuthenticated = false;
        break;
      case 'MESSAGE':
        _handleStompDataMessage(lines);
        break;
      default:
        _logger.d('알 수 없는 STOMP 메시지: $command');
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
          try {
            final jsonData = json.decode(body);
            _messageController.add(jsonData);
          } catch (e) {
            _logger.e('JSON 파싱 실패: $e, 본문: $body');
          }
        }
      }
    } catch (e, stackTrace) {
      _logger.e('STOMP 메시지 파싱 실패: $e');
      _logger.e('스택 트레이스: $stackTrace');
    }
  }

  void _cleanup() {
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
      
      if (kDebugMode) {
        _logger.i('토큰 확인: ${token.substring(0, 20)}...');
        // 개발 모드에서만 토큰 마스킹하여 로깅
        final maskedToken = token.length > 10 
            ? '${token.substring(0, 6)}${'*' * (token.length - 10)}${token.substring(token.length - 4)}'
            : '***';
        _logger.i('🔑 백엔드 액세스 토큰: $maskedToken (총 ${token.length}자)');
      } else {
        _logger.i('백엔드 액세스 토큰 확인됨 (길이: ${token.length}자)');
      }
      
      final frame = 'CONNECT\n'
          'accept-version:1.2\n'
          'host:realtime\n'
          'Authorization:Bearer $token\n'
          'heart-beat:10000,10000\n'
          '\n'
          '\x00';

      _channel?.sink.add(frame);
      
    } catch (e) {
      _logger.e('STOMP CONNECT 전송 실패: $e');
    }
  }

  // 주문 상태 업데이트 구독
  Future<void> _subscribeToOrders() async {
    try {
      final frame = 'SUBSCRIBE\n'
          'id:orders-subscription\n'
          'destination:/user/queue/orders\n'
          '\n'
          '\x00';
      _channel?.sink.add(frame);
      _logger.i('주문 업데이트 구독 요청: /user/queue/orders');
    } catch (e) {
      _logger.e('STOMP SUBSCRIBE 전송 실패: $e');
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
        // 백엔드 메시지 구조 변환
        // 백엔드: { type: "order_update", order: { alpacaOrderId, symbol, status, ... } }
        // 프론트엔드: { type, orderId, symbol, status, ... }
        final messageMap = message as Map<String, dynamic>;
        final orderData = messageMap['order'] as Map<String, dynamic>?;
        
        if (orderData != null) {
          // order 객체를 flat하게 변환
          final flatMessage = Map<String, dynamic>.from(messageMap);
          flatMessage.remove('order');
          flatMessage.addAll(orderData);
          
          return OrderUpdateMessage.fromJson(flatMessage);
        } else {
          // 이미 flat한 구조인 경우
          return OrderUpdateMessage.fromJson(messageMap);
        }
      } catch (e, stackTrace) {
        _logger.e('주문 업데이트 메시지 파싱 실패: $e');
        _logger.e('메시지 내용: $message');
        _logger.e('스택 트레이스: $stackTrace');
        throw e;
      }
    });
  }

  // TradeCycle 업데이트 스트림
  Stream<TradeCycle> get tradeCycleUpdates {
    return messages.where((message) {
      if (message is Map<String, dynamic>) {
        // TradeCycle 관련 메시지 필터링
        return message['type'] == 'trade_cycle_update' ||
               message['type'] == 'cycle_update' ||
               message['type'] == 'trade_cycle' ||
               message.containsKey('cycleId') ||
               message.containsKey('tradeCycleId') ||
               (message.containsKey('symbol') && message.containsKey('side'));
      }
      return false;
    }).map((message) {
      try {
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