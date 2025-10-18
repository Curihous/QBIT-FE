import 'package:flutter/material.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_services/api/stock_api_service.dart';
import 'package:qbit_services/models/stock_model.dart';
import 'package:qbit_services/models/orderbook_model.dart';
import 'package:qbit_shared/widgets/trade/orderbook_widget.dart';

class StockOrderbookTab extends StatefulWidget {
  final String symbol;
  final String name;
  final String assetClass;

  const StockOrderbookTab({
    super.key,
    required this.symbol,
    required this.name,
    required this.assetClass,
  });

  @override
  State<StockOrderbookTab> createState() => _StockOrderbookTabState();
}

class _StockOrderbookTabState extends State<StockOrderbookTab> {
  OrderBookModel? _orderBook;
  bool _isLoadingOrderBook = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
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
    });

    try {
      final orderBook = await StockApiService.getCryptoOrderBook(widget.symbol);
      if (mounted) {
        setState(() {
          _orderBook = orderBook;
          _isLoadingOrderBook = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _orderBook = null;
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

    // 암호화폐 호가창 표시
    return OrderBookWidget(
      symbol: widget.symbol,
      orderBook: _orderBook,
      isLoading: _isLoadingOrderBook,
      onRefresh: _loadOrderBook,
    );
  }
}

