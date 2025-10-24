import 'dart:async';
import 'dart:convert';

import 'package:logger/logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:qbit_services/storage/token_service.dart';

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
  int _reconnectAttempts = 0;

  Stream<dynamic> get messages => _messageController.stream;

  Future<void> connect() async {
    if (_connecting || _channel != null) return;
    _connecting = true;
    _manuallyClosed = false;

    try {
      // 연결 시도 로그 제거 
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      // 수신 스트림 리스닝
      _channelSub = _channel!.stream.listen(
        (event) {
          // 에러만 로깅
          dynamic parsed = event;
          try {
            if (event is String) {
              parsed = json.decode(event);
            }
          } catch (_) {}
          _messageController.add(parsed);
        },
        onDone: () {
          // 연결 종료 로그 제거
          _cleanup();
          if (!_manuallyClosed) _scheduleReconnect();
        },
        onError: (error) {
          _logger.e('WS 에러: $error');
          _cleanup();
          if (!_manuallyClosed) _scheduleReconnect();
        },
        cancelOnError: true,
      );

      _reconnectAttempts = 0;
      // STOMP CONNECT 프레임 송신
      await _sendStompConnect();
    } finally {
      _connecting = false;
    }
  }

  void _scheduleReconnect() {
    _reconnectAttempts++;
    final delayMs = (1000 * (_reconnectAttempts.clamp(1, 10))).toInt();
    // 재연결 로그 제거 
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (_manuallyClosed) return;
      connect();
    });
  }

  void _cleanup() {
    _channelSub?.cancel();
    _channelSub = null;
    _channel = null;
  }

  Future<void> disconnect() async {
    _manuallyClosed = true;
    try {
      await _channel?.sink.close(status.normalClosure);
    } catch (_) {}
    _cleanup();
  }

  void dispose() {
    _messageController.close();
    _cleanup();
  }

  // --- STOMP helpers ---
  Future<void> _sendStompConnect() async {
    try {
      final token = await TokenService.getAccessToken();
      final buffer = StringBuffer();
      buffer.writeln('CONNECT');
      buffer.writeln('accept-version:1.2');
      buffer.writeln('host:realtime');
      if (token != null) {
        buffer.writeln('Authorization: Bearer $token');
      }
      buffer.writeln('heart-beat:10000,10000');
      buffer.write('\u0000'); // STOMP frame terminator

      final frame = buffer.toString();
      // STOMP CONNECT 로그 제거 
      _channel?.sink.add(frame);
      
      // CONNECT 후 구독 요청
      await Future.delayed(const Duration(milliseconds: 500));
      await _subscribeToOrders();
    } catch (e) {
      _logger.e('STOMP CONNECT 전송 실패: $e');
    }
  }

  // 주문 상태 업데이트 구독
  Future<void> _subscribeToOrders() async {
    try {
      final buffer = StringBuffer();
      buffer.writeln('SUBSCRIBE');
      buffer.writeln('id:orders-subscription');
      buffer.writeln('destination:/user/queue/orders');
      buffer.write('\u0000'); // STOMP frame terminator

      final frame = buffer.toString();
      // STOMP SUBSCRIBE 로그 제거 
      _channel?.sink.add(frame);
    } catch (e) {
      _logger.e('STOMP SUBSCRIBE 전송 실패: $e');
    }
  }

  // 주문 상태 업데이트 스트림
  Stream<Map<String, dynamic>> get orderUpdates {
    return messages.where((message) {
      if (message is Map<String, dynamic>) {
        // 주문 관련 메시지만 필터링
        return message.containsKey('orderId') || 
               message.containsKey('status') ||
               message.containsKey('symbol');
      }
      return false;
    }).cast<Map<String, dynamic>>();
  }
}


