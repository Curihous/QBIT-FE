import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:logger/logger.dart';

class CryptoTickerWebSocket {
  WebSocketChannel? _channel;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  final Logger logger = Logger();

  Stream<Map<String, dynamic>> get tickerStream => _controller.stream;

  Future<void> connect(String symbol) async {
    try {
      // 심볼에서 '/' 제거 (ETH/USDT -> ETHUSDT)
      final cleanSymbol = symbol.replaceAll('/', '');
      final url = Uri.parse('ws://15.165.205.46:8081/ws/ticker/$cleanSymbol');
      
      logger.i('CryptoTickerWebSocket 연결 시도: $url');
      
      _channel = WebSocketChannel.connect(url);
      
      _channel!.stream.listen(
        (data) {
          try {
            final jsonData = jsonDecode(data);
            // logger.d('Ticker 데이터 수신: $jsonData');
            
            // 데이터 변환 (단축 키 -> 친화적 키)
            final transformedData = {
              'price': jsonData['c'], // 현재가
              'change': jsonData['p'], // 변동폭
              'changePercent': jsonData['P'], // 변동률
              'high': jsonData['h'], // 고가
              'low': jsonData['l'], // 저가
              'volume': jsonData['v'], // 거래량
              'quoteVolume': jsonData['q'], // 거래대금
              'prevClose': jsonData['x'], // 전일 종가
            };
            
            _controller.add(transformedData);
          } catch (e) {
            logger.e('Ticker 데이터 파싱 에러: $e');
          }
        },
        onError: (error) {
          logger.e('Ticker WebSocket 에러: $error');
          _controller.addError(error);
        },
        onDone: () {
          logger.i('Ticker WebSocket 연결 종료');
        },
      );
    } catch (e) {
      logger.e('Ticker WebSocket 연결 실패: $e');
      rethrow;
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
    _controller.close();
  }
}
