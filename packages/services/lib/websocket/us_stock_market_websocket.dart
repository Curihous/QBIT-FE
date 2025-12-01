import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logger/logger.dart';

/// 미국 주식 시세용 Polygon(Massive) WebSocket 클라이언트
/// Singleton 패턴 적용
class UsStockMarketWebSocket {
  static const String _wsUrl = 'wss://delayed.massive.com/stocks';
  static const Duration _baseReconnectDelay = Duration(seconds: 2);
  static const int _maxReconnectAttempts = 5;

  static UsStockMarketWebSocket? _instance;
  
  final Logger _logger = Logger();
  String? _apiKey;

  WebSocket? _socket;
  StreamSubscription? _subscription;
  final _controller = StreamController<PolygonEvent>.broadcast();

  bool _connecting = false;
  bool _manuallyClosed = false;
  int _reconnectAttempts = 0;
  
  // 구독한 심볼 추적 (재연결 시 복원용)
  final Set<String> _subscribedSymbols = {};

  // Private constructor
  UsStockMarketWebSocket._();

  static UsStockMarketWebSocket get instance {
    _instance ??= UsStockMarketWebSocket._();
    return _instance!;
  }

  Stream<PolygonEvent> get stream => _controller.stream;
  
  bool get isConnected => _socket != null && _socket!.readyState == WebSocket.open;
  
  /// 디버그/테스트용: WebSocket 연결을 강제로 종료
  /// Postman 등에서 테스트할 때 사용
  static Future<void> forceClose() async {
    if (_instance != null) {
      await _instance!.close();
      _instance = null;
    }
  }

  Future<void> connect({String? apiKey, List<String> initialSymbols = const []}) async {
    if (apiKey != null) {
      _apiKey = apiKey;
    }

    // 이미 연결되어 있으면 구독만 추가하고 리턴
    if (isConnected) {
      _logger.d('이미 연결되어 있음 → 구독만 추가');
      if (initialSymbols.isNotEmpty) {
        subscribe(initialSymbols);
      }
      return;
    }

    // 연결 중이면 대기
    if (_connecting) {
      _logger.d('연결 중... 대기');
      // 연결 완료까지 대기 (최대 5초)
      int waitCount = 0;
      while (_connecting && waitCount < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        waitCount++;
        if (isConnected) {
          if (initialSymbols.isNotEmpty) {
            subscribe(initialSymbols);
          }
          return;
        }
      }
      if (_connecting) {
        _logger.w('연결 대기 시간 초과');
        return;
      }
    }

    if (_apiKey == null) {
      _logger.e('API Key가 설정되지 않았습니다.');
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
      _sendJson({'action': 'auth', 'params': _apiKey});

      // 이전에 구독했던 심볼들 복구
      if (_subscribedSymbols.isNotEmpty) {
        subscribe(_subscribedSymbols.toList());
      }
      
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
    if (symbols.isEmpty) return;
    
    // 구독 목록 업데이트
    _subscribedSymbols.addAll(symbols);

    if (_socket == null) return;

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
    if (symbols.isEmpty) return;
    
    // 구독 목록에서 제거
    _subscribedSymbols.removeAll(symbols);

    if (_socket == null) return;

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
    _subscribedSymbols.clear();
    await _subscription?.cancel();
    await _socket?.close();
    _subscription = null;
    _socket = null;
    _logger.i('미국 주식 웹소켓 종료');
  }

  void dispose() {
    // Singleton이므로 dispose하지 않음 (앱 종료 시까지 유지)
    // close();
    // _controller.close();
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
      _logger.d('WebSocket 메시지 수신: $data');
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) {
        _handleSystemMessage(decoded);
      } else if (decoded is List) {
        _logger.d('데이터 배열 수신: ${decoded.length}개 항목');
        for (final raw in decoded) {
          if (raw is Map<String, dynamic>) {
            // status 메시지는 시스템 메시지로 처리
            if (raw['status'] != null) {
              _handleSystemMessage(raw);
            } else {
              // 이벤트 데이터 파싱
              final event = PolygonEvent.fromJson(raw);
              if (event != null) {
                _logger.d('이벤트 파싱 성공: ${event.symbol}');
                _controller.add(event);
              } else {
                _logger.w('이벤트 파싱 실패: $raw');
              }
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
    final ev = data['ev'];
    
    // ev가 있으면 이벤트 데이터일 수 있음
    if (ev != null && status == null) {
      _logger.d('이벤트 데이터 (시스템 메시지로 처리됨): $data');
      // 이벤트 데이터를 다시 처리
      final event = PolygonEvent.fromJson(data);
      if (event != null) {
        _logger.d('이벤트 파싱 성공: ${event.symbol}');
        _controller.add(event);
      }
      return;
    }
    
    if (status == null) {
      _logger.d('기타 시스템 메시지: $data');
      return;
    }

    _logger.i('시스템 메시지: $data');

    if (status == 'connected') {
      _reconnectAttempts = 0;
      _logger.i('WebSocket 연결됨');
    } else if (status == 'auth_success') {
      _logger.i('Polygon 인증 성공');
    } else if (status == 'auth_failed') {
      _logger.e('Polygon 인증 실패 → 연결 종료');
      close();
    } else if (status == 'max_connections') {
      _logger.e('최대 연결 수 초과! 이미 다른 연결이 활성화되어 있습니다.');
      _logger.e('메시지: ${data['message']}');
      // 연결 종료하고 재연결 시도하지 않음
      _manuallyClosed = true;
      _reconnectAttempts = _maxReconnectAttempts; // 재연결 방지
      close();
    } else {
      _logger.w('알 수 없는 상태: $status');
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
