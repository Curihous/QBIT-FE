import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logger/logger.dart';

/// 미국 주식 시세용 Polygon(Massive) WebSocket 클라이언트
/// 기존 crypto_websocket 서비스와 유사한 사용법으로 구현했습니다.
class UsStockMarketWebSocket {
  static const String _wsUrl = 'wss://delayed.massive.com/stocks';
  static const Duration _baseReconnectDelay = Duration(seconds: 2);
  static const int _maxReconnectAttempts = 2; // 재연결 시도 횟수 감소 (빠른 REST API 폴백)

  final Logger _logger = Logger();
  final String apiKey;

  WebSocket? _socket;
  StreamSubscription? _subscription;
  final _controller = StreamController<PolygonEvent>.broadcast();

  bool _connecting = false;
  bool _manuallyClosed = false;
  int _reconnectAttempts = 0;
  
  // 구독한 심볼 추적 (재연결 시 복원용)
  final Set<String> _subscribedSymbols = {};

  UsStockMarketWebSocket(this.apiKey);

  Stream<PolygonEvent> get stream => _controller.stream;

  Future<void> connect({List<String> initialSymbols = const []}) async {
    if (_socket != null || _connecting) {
      _logger.d('이미 연결되었거나 연결 중입니다.');
      return;
    }

    _connecting = true;
    _manuallyClosed = false;

    try {
      _logger.i('Polygon WebSocket 연결 시도: $_wsUrl');
      _socket = await WebSocket.connect(_wsUrl);
      _subscription = _socket!.listen(
        _handleMessage,
        onDone: _handleDone,
        onError: _handleError,
        cancelOnError: true,
      );

      _logger.i('연결 성공 → 인증 메시지 전송');
      _sendJson({'action': 'auth', 'params': apiKey});

      if (initialSymbols.isNotEmpty) {
        subscribe(initialSymbols);
      }
    } catch (error, stack) {
      _logger.e('연결 실패: $error');
      _logger.e('$stack');
      _scheduleReconnect();
    } finally {
      _connecting = false;
    }
  }

  void subscribe(List<String> symbols,
      {bool trade = true, bool aggregateMinute = true, bool aggregateSecond = false, bool quote = false}) {
    if (_socket == null || symbols.isEmpty) return;

    final channels = <String>[];
    for (final symbol in symbols) {
      if (trade) channels.add('T.$symbol');
      if (quote) channels.add('Q.$symbol');
      if (aggregateSecond) channels.add('A.$symbol');
      if (aggregateMinute) channels.add('AM.$symbol');
    }

    if (channels.isEmpty) return;
    _logger.i('구독 요청: ${channels.join(',')}');
    _sendJson({'action': 'subscribe', 'params': channels.join(',')});
  }

  void unsubscribe(List<String> symbols,
      {bool trade = true, bool aggregateMinute = true, bool aggregateSecond = false, bool quote = false}) {
    if (_socket == null || symbols.isEmpty) return;

    final channels = <String>[];
    for (final symbol in symbols) {
      if (trade) channels.add('T.$symbol');
      if (quote) channels.add('Q.$symbol');
      if (aggregateSecond) channels.add('A.$symbol');
      if (aggregateMinute) channels.add('AM.$symbol');
    }

    if (channels.isEmpty) return;
    _logger.i('구독 해제: ${channels.join(',')}');
    _sendJson({'action': 'unsubscribe', 'params': channels.join(',')});
  }

  Future<void> close() async {
    _manuallyClosed = true;
    _reconnectAttempts = 0;
    await _subscription?.cancel();
    await _socket?.close();
    _subscription = null;
    _socket = null;
    _logger.i('미국 주식 웹소켓 종료');
  }

  void dispose() {
    close();
    _controller.close();
  }

  void _sendJson(Map<String, dynamic> json) {
    try {
      _socket?.add(jsonEncode(json));
    } catch (e) {
      _logger.e('메시지 전송 실패: $e');
    }
  }

  void _handleMessage(dynamic data) {
    try {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) {
        _handleSystemMessage(decoded);
      } else if (decoded is List) {
        for (final raw in decoded) {
          if (raw is Map<String, dynamic>) {
            final event = PolygonEvent.fromJson(raw);
            if (event != null) {
              _controller.add(event);
            }
          }
        }
      }
    } catch (error, stack) {
      _logger.e('메시지 파싱 실패: $error');
      _logger.e('$stack');
    }
  }

  void _handleSystemMessage(Map<String, dynamic> data) {
    final status = data['status'];
    if (status == null) {
      _logger.d('기타 시스템 메시지: $data');
      return;
    }

    _logger.i('시스템 메시지: $data');

    if (status == 'connected') {
      _reconnectAttempts = 0;
    } else if (status == 'auth_success') {
      _logger.i('Polygon 인증 성공');
    } else if (status == 'auth_failed') {
      _logger.w('Polygon 인증 실패 → 연결 종료');
      close();
    }
  }

  void _handleDone() {
    _logger.w('웹소켓 연결 종료(onDone)');
    _socket = null;
    _subscription = null;
    if (!_manuallyClosed) {
      _scheduleReconnect();
    }
  }

  void _handleError(dynamic error, StackTrace stack) {
    _logger.e('웹소켓 에러: $error');
    _logger.e('$stack');
    _socket = null;
    _subscription = null;
    if (!_manuallyClosed) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_manuallyClosed) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _logger.w('재연결 최대 횟수 초과($_maxReconnectAttempts) → 중단');
      return;
    }

    _reconnectAttempts++;
    final delay = _baseReconnectDelay * _reconnectAttempts;
    _logger.i('재연결 시도 $_reconnectAttempts/$_maxReconnectAttempts (지연 ${delay.inSeconds}s)');
    Future.delayed(delay, () {
      if (!_manuallyClosed) {
        connect();
      }
    });
  }
}

// ───────────────── Polygon 이벤트 모델 ─────────────────
abstract class PolygonEvent {
  final String symbol;
  final DateTime timestamp;

  PolygonEvent(this.symbol, this.timestamp);

  static PolygonEvent? fromJson(Map<String, dynamic> json) {
    final type = json['ev'] as String?;
    if (type == null) return null;

    switch (type) {
      case 'AM':
        return PolygonAggregateMinute.fromJson(json);
      case 'A':
        return PolygonAggregateSecond.fromJson(json);
      case 'T':
        return PolygonTrade.fromJson(json);
      case 'Q':
        return PolygonQuote.fromJson(json);
      default:
        return null;
    }
  }

  static DateTime parseTimestamp(dynamic value) {
    if (value is int) {
      // Polygon은 밀리초 기준 타임스탬프
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
  }
}

class PolygonAggregateMinute extends PolygonEvent {
  final double open;
  final double high;
  final double low;
  final double close;
  final double? vwap;
  final int volume;

  PolygonAggregateMinute.fromJson(Map<String, dynamic> json)
      : open = (json['o'] as num).toDouble(),
        high = (json['h'] as num).toDouble(),
        low = (json['l'] as num).toDouble(),
        close = (json['c'] as num).toDouble(),
        vwap = json.containsKey('a') ? (json['a'] as num).toDouble() : null,
        volume = (json['v'] as num).toInt(),
        super(json['sym'] as String, PolygonEvent.parseTimestamp(json['e'] ?? json['t']));
}

class PolygonAggregateSecond extends PolygonEvent {
  final double open;
  final double high;
  final double low;
  final double close;
  final int volume;
  final int? accumulatedVolume; // av: 오늘의 누적 거래량
  final double? vwap; // vw: 틱의 거래량 가중 평균 가격
  final double? dailyVwap; // a: 오늘의 거래량 가중 평균 가격
  final int? averageTradeSize; // z: 평균 거래 크기
  final DateTime? startTime; // s: 집계 윈도우 시작 시간
  final DateTime? endTime; // e: 집계 윈도우 종료 시간

  PolygonAggregateSecond.fromJson(Map<String, dynamic> json)
      : open = (json['o'] as num).toDouble(),
        high = (json['h'] as num).toDouble(),
        low = (json['l'] as num).toDouble(),
        close = (json['c'] as num).toDouble(),
        volume = (json['v'] as num).toInt(),
        accumulatedVolume = json['av'] != null ? (json['av'] as num).toInt() : null,
        vwap = json['vw'] != null ? (json['vw'] as num).toDouble() : null,
        dailyVwap = json['a'] != null ? (json['a'] as num).toDouble() : null,
        averageTradeSize = json['z'] != null ? (json['z'] as num).toInt() : null,
        startTime = json['s'] != null ? DateTime.fromMillisecondsSinceEpoch(json['s'] as int) : null,
        endTime = json['e'] != null ? DateTime.fromMillisecondsSinceEpoch(json['e'] as int) : null,
        super(json['sym'] as String, PolygonEvent.parseTimestamp(json['t']));
}

class PolygonTrade extends PolygonEvent {
  final double price;
  final int size;

  PolygonTrade.fromJson(Map<String, dynamic> json)
      : price = (json['p'] as num).toDouble(),
        size = (json['s'] as num).toInt(),
        super(json['sym'] as String, PolygonEvent.parseTimestamp(json['t']));
}

class PolygonQuote extends PolygonEvent {
  final double bidPrice;
  final double askPrice;
  final int bidSize;
  final int askSize;

  PolygonQuote.fromJson(Map<String, dynamic> json)
      : bidPrice = (json['bp'] as num).toDouble(),
        askPrice = (json['ap'] as num).toDouble(),
        bidSize = (json['bs'] as num).toInt(),
        askSize = (json['as'] as num).toInt(),
        super(json['sym'] as String, PolygonEvent.parseTimestamp(json['t']));
}
