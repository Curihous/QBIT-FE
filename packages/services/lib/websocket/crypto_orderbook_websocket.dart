import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:logger/logger.dart';
import '../models/orderbook_model.dart';

class CryptoOrderBookWebSocket {
  static final Logger logger = Logger();
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final StreamController<OrderBookModel> _orderBookController = StreamController<OrderBookModel>.broadcast();
  
  /// 호가창 데이터 스트림
  Stream<OrderBookModel> get orderBookStream => _orderBookController.stream;
  
  /// WebSocket 연결 시작
  /// ws://15.165.205.46:8081/ws/depth/{binanceSymbol}
  Future<void> connect(String binanceSymbol) async {
    try {
      final wsUrl = 'ws://15.165.205.46:8081/ws/depth/$binanceSymbol';
      logger.i('WebSocket 연결 시도: $wsUrl');
      
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      _subscription = _channel!.stream.listen(
        (data) {
          try {
            final jsonData = jsonDecode(data);
            logger.d('WebSocket 데이터 수신: $jsonData');
            
            // WebSocket 응답 형식에 맞게 데이터 변환
            final transformedData = {
              'symbol': jsonData['symbol'],
              'bids': (jsonData['bids'] as List).map((bid) => {
                'price': bid['price'].toString(),
                'quantity': bid['quantity'].toString(),
              }).toList(),
              'asks': (jsonData['asks'] as List).map((ask) => {
                'price': ask['price'].toString(),
                'quantity': ask['quantity'].toString(),
              }).toList(),
            };
            
            final orderBook = OrderBookModel.fromJson(transformedData);
            _orderBookController.add(orderBook);
          } catch (e) {
            logger.e('WebSocket 데이터 파싱 에러: $e');
          }
        },
        onError: (error) {
          logger.e('WebSocket 에러: $error');
        },
        onDone: () {
          logger.i('WebSocket 연결 종료');
        },
      );
      
      logger.i('WebSocket 연결 성공');
    } catch (e) {
      logger.e('WebSocket 연결 에러: $e');
    }
  }
  
  /// WebSocket 연결 종료
  Future<void> disconnect() async {
    try {
      await _subscription?.cancel();
      await _channel?.sink.close();
      logger.i('WebSocket 연결 종료 완료');
    } catch (e) {
      logger.e('WebSocket 종료 에러: $e');
    }
  }
  
  /// 스트림 컨트롤러 정리
  void dispose() {
    _orderBookController.close();
  }
}
