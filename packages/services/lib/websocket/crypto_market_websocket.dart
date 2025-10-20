import 'dart:async';
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// 암호화폐 체결/마켓 데이터 WebSocket (최근 체결 가격 중심)
class CryptoMarketWebSocket {
  static final Logger logger = Logger();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  final StreamController<double> _lastPriceController =
      StreamController<double>.broadcast();

  /// 최근 체결 가격 스트림
  Stream<double> get lastPriceStream => _lastPriceController.stream;

  /// WebSocket 연결 시작
  Future<void> connect(String symbol) async {
    try {
      final cleanSymbol = symbol.replaceAll('/', '');
      final wsUrl = 'ws://15.165.205.46:8081/ws/market/$cleanSymbol';
      logger.i('Market WS 연결 시도: $wsUrl');

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _subscription = _channel!.stream.listen(
        (data) {
          try {
            final jsonData = jsonDecode(data);

            // 가능한 키들에서 가격 추출 시도
            final dynamic priceRaw = jsonData['price'] ?? jsonData['lastPrice'] ?? jsonData['p'];
            if (priceRaw != null) {
              final price = priceRaw is num
                  ? priceRaw.toDouble()
                  : double.tryParse(priceRaw.toString());
              if (price != null) {
                _lastPriceController.add(price);
              }
            }
          } catch (e) {
            logger.e('Market WS 데이터 파싱 에러: $e');
          }
        },
        onError: (error) {
          logger.e('Market WS 에러: $error');
        },
        onDone: () {
          logger.i('Market WS 연결 종료');
        },
      );

      logger.i('Market WS 연결 성공');
    } catch (e) {
      logger.e('Market WS 연결 에러: $e');
    }
  }

  /// WebSocket 연결 종료
  Future<void> disconnect() async {
    try {
      await _subscription?.cancel();
      await _channel?.sink.close();
      logger.i('Market WS 연결 종료 완료');
    } catch (e) {
      logger.e('Market WS 종료 에러: $e');
    }
  }

  void dispose() {
    _lastPriceController.close();
  }
}


