import 'dart:async';
import 'package:qbit_services/websocket/crypto_orderbook_websocket.dart';
import 'package:qbit_services/websocket/us_stock_market_websocket.dart';
import 'package:qbit_services/models/orderbook_model.dart';
import 'package:qbit_services/api/stock_api_service.dart';

/// 호가 데이터 저장소
/// 자산 종류에 따라 적절한 WebSocket 또는 API를 선택하여 데이터를 제공합니다.
class OrderBookRepository {
  CryptoOrderBookWebSocket? _cryptoSocket;
  UsStockMarketWebSocket? _usStockSocket;
  
  // WebSocket 스트림 컨트롤러
  final _orderBookController = StreamController<OrderBookModel>.broadcast();
  Stream<OrderBookModel> get orderBookStream => _orderBookController.stream;

  /// 연결
  Future<void> connect({
    required String assetClass,
    required String symbol,
  }) async {
    // 기존 연결 해제
    disconnect();

    if (assetClass == 'crypto') {
      _connectCrypto(symbol);
    } else {
      _connectUsStock(symbol);
    }
  }

  // 시장가 스트림 컨트롤러
  final _marketPriceController = StreamController<double>.broadcast();
  Stream<double> get marketPriceStream => _marketPriceController.stream;

  /// 암호화폐 연결
  Future<void> _connectCrypto(String symbol) async {
    _cryptoSocket = CryptoOrderBookWebSocket();
    await _cryptoSocket!.connect(symbol);
    
    _cryptoSocket!.orderBookStream.listen(
      (data) {
        // print('OrderBookRepository: 데이터 수신');
        _orderBookController.add(data);
        // 호가 데이터에서 중간 가격 계산하여 시장가 스트림에도 전달 (임시)
        if (data.bids.isNotEmpty && data.asks.isNotEmpty) {
          final midPrice = (data.bids.first.price + data.asks.first.price) / 2;
          _marketPriceController.add(midPrice);
        }
      },
      onError: (error) {
        _orderBookController.addError(error);
      },
    );
  }

  /// 미국 주식 연결
  Future<void> _connectUsStock(String symbol) async {
    // 미국 주식은 현재 WebSocket 구조가 다르므로, 
    // 여기서는 기존 로직을 참고하여 구현하거나 추후 확장을 위해 비워둡니다.
    // 현재 StockOrderTab에서는 UsStockOrderBookWidget이 자체적으로 소켓을 관리하므로
    // 이 리포지토리는 주로 암호화폐용으로 사용되거나, 추후 통합될 예정입니다.
    
    // TODO: 미국 주식 WebSocket 통합 구현
    // 현재는 StockOrderTab에서 별도로 처리 중
  }

  /// 연결 해제
  void disconnect() {
    _cryptoSocket?.disconnect();
    // UsStockMarketWebSocket은 disconnect 메서드가 없고 close 메서드를 사용하거나
    // 내부적으로 관리됨. 여기서는 null check만 수행.
    // _usStockSocket?.disconnect(); 
  }
  
  void dispose() {
    disconnect();
    _orderBookController.close();
    _marketPriceController.close();
  }
}
