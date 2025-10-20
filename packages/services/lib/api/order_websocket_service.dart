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
      _logger.i('WS 연결 시도: $_wsUrl');
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      // 수신 스트림 리스닝
      _channelSub = _channel!.stream.listen(
        (event) {
          _logger.d('WS 수신: $event');
          dynamic parsed = event;
          try {
            if (event is String) {
              parsed = json.decode(event);
            }
          } catch (_) {}
          _messageController.add(parsed);
        },
        onDone: () {
          _logger.w('WS 연결 종료 (code: ${_channel?.closeCode})');
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
    _logger.i('WS 재연결 예약: ${delayMs}ms 후 (${_reconnectAttempts}회 시도)');
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
      _logger.i('STOMP CONNECT 전송');
      _channel?.sink.add(frame);
    } catch (e) {
      _logger.e('STOMP CONNECT 전송 실패: $e');
    }
  }
}


