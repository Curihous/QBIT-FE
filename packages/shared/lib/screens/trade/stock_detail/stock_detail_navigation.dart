import 'package:flutter/material.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_shared/screens/trade/stock_detail/stock_chart_tab.dart';
import 'package:qbit_shared/screens/trade/stock_detail/stock_orderbook_tab.dart';
import 'package:qbit_shared/screens/trade/stock_detail/stock_order_tab.dart';
import 'package:qbit_shared/screens/trade/stock_detail/stock_market_tab.dart';
import 'package:qbit_shared/widgets/common/header_back.dart';

class StockDetailNavigation extends StatefulWidget {
  final String symbol;
  final String name;
  final String assetClass;

  const StockDetailNavigation({
    super.key,
    required this.symbol,
    required this.name,
    required this.assetClass,
  });

  @override
  State<StockDetailNavigation> createState() => _StockDetailNavigationState();
}

class _StockDetailNavigationState extends State<StockDetailNavigation> {
  int _selectedTabIndex = 0; // 0: 차트, 1: 호가, 2: 주문, 3: 시세

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: HeaderBack(
        title: widget.name,
        onBackPressed: () => Navigator.pop(context),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _buildTabContent(),
              ),
              _buildBottomTabNavigation(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0: // 차트
        return StockChartTab(
          symbol: widget.symbol,
          name: widget.name,
          assetClass: widget.assetClass,
        );
      case 1: // 호가
        return StockOrderbookTab(
          symbol: widget.symbol,
          name: widget.name,
          assetClass: widget.assetClass,
        );
      case 2: // 주문
        return StockOrderTab(
          symbol: widget.symbol,
          name: widget.name,
          assetClass: widget.assetClass,
        );
      case 3: // 시세
        return StockMarketTab(
          symbol: widget.symbol,
          name: widget.name,
        );
      default:
        return StockChartTab(
          symbol: widget.symbol,
          name: widget.name,
          assetClass: widget.assetClass,
        );
    }
  }

  Widget _buildBottomTabNavigation() {
    return Container(
      padding: const EdgeInsets.fromLTRB(72, 16, 72, 44),
      child: Container(
        width: 249,
        height: 49,
        decoration: ShapeDecoration(
          color: AppColors.gray600.withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildTabItem('차트', 0),
            _buildTabItem('호가', 1),
            _buildTabItem('주문', 2),
            _buildTabItem('시세', 3),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(String title, int index) {
    final isSelected = _selectedTabIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Text(
          title,
          style: AppFonts.b1Semibold.copyWith(
            color: isSelected ? AppColors.primary : Colors.white,
          ),
        ),
      ),
    );
  }
}

