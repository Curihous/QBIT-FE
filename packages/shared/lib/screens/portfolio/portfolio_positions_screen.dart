import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_shared/widgets/common/app_header.dart';
import 'package:qbit_services/api/stock_api_service.dart';
import 'package:qbit_shared/utils/stock_price_parser.dart';
import 'package:intl/intl.dart';

import 'package:qbit_shared/widgets/common/button/filter_button.dart';
import 'package:qbit_shared/widgets/common/empty_widget.dart';

class PortfolioPositionsScreen extends StatefulWidget {
  const PortfolioPositionsScreen({super.key});

  @override
  State<PortfolioPositionsScreen> createState() => _PortfolioPositionsScreenState();
}

class _PortfolioPositionsScreenState extends State<PortfolioPositionsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allPositions = [];
  List<Map<String, dynamic>> _filteredPositions = [];
  final TextEditingController _searchController = TextEditingController();
  String _currentSort = 'marketValue'; // marketValue, return, symbol

  @override
  void initState() {
    super.initState();
    _fetchPositions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPositions() async {
    setState(() => _isLoading = true);
    final positions = await StockApiService.getPortfolioPositions();
    if (mounted) {
      setState(() {
        _allPositions = positions ?? [];
        _applyFilterAndSort();
        _isLoading = false;
      });
    }
  }

  void _applyFilterAndSort() {
    List<Map<String, dynamic>> result = List.from(_allPositions);
    
    // Sort
    result.sort((a, b) {
      switch (_currentSort) {
        case 'marketValue':
          final aVal = StockPriceParser.parseDouble(a['marketValue']);
          final bVal = StockPriceParser.parseDouble(b['marketValue']);
          return bVal.compareTo(aVal); // Descending
        case 'return':
          final aVal = StockPriceParser.parseDouble(a['unrealizedPlpc']);
          final bVal = StockPriceParser.parseDouble(b['unrealizedPlpc']);
          return bVal.compareTo(aVal); // Descending
        default:
          return 0;
      }
    });

    _filteredPositions = result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppHeader(
        title: '내 종목',
        showBack: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sort Filters
          FilterButtonGroup(
            labels: const ['평가금액순', '수익률순'],
            values: const ['marketValue', 'return'],
            initialValue: ['marketValue', 'return'].contains(_currentSort) ? _currentSort : 'marketValue',
            onChanged: (value) {
              setState(() {
                _currentSort = value;
                _applyFilterAndSort();
              });
            },
            groupPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPositions.isEmpty
                    ? EmptyWidget(message: '보유한 종목이 없습니다.')
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _filteredPositions.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 24),
                        itemBuilder: (context, index) {
                          return _PortfolioPositionItem(position: _filteredPositions[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _PortfolioPositionItem extends StatelessWidget {
  final Map<String, dynamic> position;

  const _PortfolioPositionItem({required this.position});

  @override
  Widget build(BuildContext context) {
    final symbol = position['symbol'] ?? '';
    final marketValue = StockPriceParser.parseDouble(position['marketValue']);
    final avgEntryPrice = StockPriceParser.parseDouble(position['avgEntryPrice']);
    // Try both 'qty' and 'quantity' keys
    final qty = StockPriceParser.parseDouble(position['qty'] ?? position['quantity']);
    final unrealizedPlpc = StockPriceParser.parseDouble(position['unrealizedPlpc']);

    final isProfit = unrealizedPlpc >= 0;
    final profitColor = isProfit ? AppColors.profit : AppColors.loss;
    
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    
    final isCrypto = symbol.contains('/USD') || symbol.contains('BTC') || symbol.contains('ETH');
    
    String qtyText;
    if (isCrypto) {
      qtyText = qty.toStringAsFixed(4).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '') + '개';
    } else {
      qtyText = '${qty.toStringAsFixed(0)}주';
    }
    
    String avgPriceText;
    if (avgEntryPrice < 1) {
      avgPriceText = avgEntryPrice.toStringAsFixed(4).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    } else {
      avgPriceText = avgEntryPrice.toStringAsFixed(2);
    }
    
    final plpcPercent = unrealizedPlpc * 100;
    final plpcText = plpcPercent >= 0 
        ? '+${plpcPercent.toStringAsFixed(2)}%'
        : '${plpcPercent.toStringAsFixed(2)}%';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Navigate to position detail screen
          context.push('/portfolio-positions/detail/${Uri.encodeComponent(symbol)}');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4), // Added internal padding
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 44,
                height: 44,
                decoration: const ShapeDecoration(
                  color: AppColors.secondaryBG,
                  shape: OvalBorder(),
                ),
                child: ClipOval(
                  child: SvgPicture.asset(
                    'assets/icons/stock_search_screen/company-logo-basic.svg',
                    width: 44,
                    height: 44,
                  ),
                ),
              ),
              const SizedBox(width: 16), // Increased spacing
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Symbol & Market Value
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          symbol,
                          style: AppFonts.b1Semibold.copyWith(
                            color: AppColors.gray900,
                            fontSize: 16,
                            height: 1.25,
                          ),
                        ),
                        Text(
                          currencyFormat.format(marketValue),
                          style: AppFonts.b1Semibold.copyWith(
                            color: AppColors.gray900, 
                            fontSize: 16,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Bottom Row: Details & Return %
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '내 평균 $avgPriceText • $qtyText',
                          style: AppFonts.c1.copyWith(
                            color: AppColors.gray600,
                            fontSize: 13,
                            height: 1.23,
                          ),
                        ),
                        Text(
                          plpcText,
                          style: AppFonts.c1.copyWith(
                            color: profitColor,
                            fontSize: 13,
                            height: 1.23,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
