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
  /// ws://15.165.205.46:8081/ws/ticker/{binanceSymbol}
  Future<void> connect(String binanceSymbol) async {
    try {
      final wsUrl = 'ws://15.165.205.46:8081/ws/ticker/$binanceSymbol';
      logger.i('Market WS 연결 시도: $wsUrl');

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _subscription = _channel!.stream.listen(
        (data) {
          try {
            final jsonData = jsonDecode(data);
            logger.d('Market WS 데이터 수신: $jsonData');

            // 암호화폐 시세 조회 WebSocket에서 현재가(최근 체결가)는 'c' 필드 사용
            final dynamic priceRaw = jsonData['c']; // 최근 체결가
            
            logger.d('추출된 가격 원본: $priceRaw');
            
            if (priceRaw != null) {
              final price = priceRaw is num
                  ? priceRaw.toDouble()
                  : double.tryParse(priceRaw.toString());
              
              if (price != null && price > 0) {
                logger.d('가격 파싱 성공: $price');
                _lastPriceController.add(price);
              } else {
                logger.w('가격 파싱 실패 또는 음수: $price');
              }
            } else {
              logger.w('가격 필드를 찾을 수 없음. 전체 데이터: $jsonData');
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


