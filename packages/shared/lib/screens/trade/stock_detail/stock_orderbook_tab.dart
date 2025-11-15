import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_services/models/orderbook_model.dart';
import 'package:qbit_services/websocket/crypto_orderbook_websocket.dart';
import 'package:qbit_shared/widgets/trade/orderbook_widget.dart';

class StockOrderbookTab extends StatefulWidget {
  final String symbol;
  final String name;
  final String assetClass;
  final String? binanceSymbol; // 암호화폐 WebSocket 연결용

  const StockOrderbookTab({
    super.key,
    required this.symbol,
    required this.name,
    required this.assetClass,
    this.binanceSymbol,
  });

  @override
  State<StockOrderbookTab> createState() => _StockOrderbookTabState();
}

class _StockOrderbookTabState extends State<StockOrderbookTab> {
  OrderBookModel? _orderBook;
  bool _isLoadingOrderBook = false;
  String? _error;
  CryptoOrderBookWebSocket? _webSocket;
  StreamSubscription<OrderBookModel>? _orderBookSubscription; // WebSocket 구독

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    // WebSocket 구독 취소
    _orderBookSubscription?.cancel();
    _orderBookSubscription = null;
    
    // WebSocket 연결 해제
    _webSocket?.disconnect();
    _webSocket?.dispose();
    _webSocket = null;
    
    super.dispose();
  }

  Future<void> _loadData() async {
    // 암호화폐인 경우에만 호가창 로드
    if (widget.assetClass == 'crypto') {
      await _loadOrderBook();
    }
  }

  Future<void> _loadOrderBook() async {
    if (widget.assetClass != 'crypto') return;
    
    setState(() {
      _isLoadingOrderBook = true;
      _error = null;
    });

    try {
      // binanceSymbol이 있으면 사용, 없으면 symbol에서 변환
      final binanceSymbol = widget.binanceSymbol ?? widget.symbol.replaceAll('/', '');
      
      if (binanceSymbol.isEmpty) {
        if (mounted) {
          setState(() {
            _error = 'binanceSymbol이 필요합니다';
            _isLoadingOrderBook = false;
          });
        }
        return;
      }
      
      // 기존 WebSocket 연결 해제 및 구독 취소
      _orderBookSubscription?.cancel();
      _orderBookSubscription = null;
      await _webSocket?.disconnect();
      _webSocket?.dispose();
      _webSocket = null;
      
      // 새로운 WebSocket 연결 (암호화폐 lv2 호가창 실시간 조회)
      _webSocket = CryptoOrderBookWebSocket();
      await _webSocket!.connect(binanceSymbol);
      
      // WebSocket 스트림 구독 (구독 저장)
      _orderBookSubscription = _webSocket!.orderBookStream.listen((updatedOrderBook) {
        if (mounted) {
          setState(() {
            _orderBook = updatedOrderBook;
            _isLoadingOrderBook = false;
          });
        }
      });
      
      // 초기 연결 대기 (약간의 지연 후 로딩 상태 해제)
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _orderBook == null) {
          setState(() {
            _isLoadingOrderBook = false;
          });
        }
      });
    } catch (e) {
      // 에러 발생 시에도 기존 연결 정리
      _orderBookSubscription?.cancel();
      _orderBookSubscription = null;
      await _webSocket?.disconnect();
      _webSocket?.dispose();
      _webSocket = null;
      
      if (mounted) {
        setState(() {
          _orderBook = null;
          _error = '호가창 연결 실패: $e';
          _isLoadingOrderBook = false;
        });
      }
      print('호가창 데이터 로드 중 에러: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingOrderBook) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: AppFonts.b1Semibold.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    // 암호화폐가 아닌 경우
    if (widget.assetClass != 'crypto') {
      return Container(
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: Text(
            '호가창은 암호화폐만 지원됩니다',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.gray600,
              fontSize: 14,
              fontFamily: 'Pretendard',
            ),
          ),
        ),
      );
    }

    // 암호화폐 호가창 표시 (WebSocket 실시간 데이터)
    return OrderBookWidget(
      symbol: widget.symbol,
      orderBook: _orderBook,
      isLoading: _isLoadingOrderBook,
      onRefresh: _loadOrderBook,
    );
  }
}

