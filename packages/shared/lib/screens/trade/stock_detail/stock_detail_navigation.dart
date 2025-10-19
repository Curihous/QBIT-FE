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

class _StockDetailNavigationState extends State<StockDetailNavigation> with TickerProviderStateMixin {
  int _selectedTabIndex = 0; // 0: 차트, 1: 호가, 2: 주문, 3: 시세
  bool _isBottomNavVisible = true;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  
  // 가격 정보 상태
  String _currentPrice = "0원";
  String _priceChange = "+0.00%";

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1), // 아래에서 시작
      end: const Offset(0, 0),   // 원래 위치
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward(); // 초기 상태는 보이는 상태
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    // 아래로 드래그 (delta.dy > 0) - 네비게이션 바 숨기기
    if (details.delta.dy > 3 && _isBottomNavVisible) {
      setState(() {
        _isBottomNavVisible = false;
      });
      _animationController.reverse();
    }
    // 위로 드래그 (delta.dy < 0) - 네비게이션 바 보이기
    else if (details.delta.dy < -3 && !_isBottomNavVisible) {
      setState(() {
        _isBottomNavVisible = true;
      });
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildCustomAppBar(),
      body: GestureDetector(
        onPanUpdate: _handlePanUpdate,
        child: Stack(
          children: [
              Column(
                children: [
                  Expanded(
                    child: _buildTabContent(),
                  ),
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildBottomTabNavigation(),
                  ),
                ],
              ),
          ],
        ),
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
          onPriceUpdate: updatePriceInfo,
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

  PreferredSizeWidget _buildCustomAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios,
          color: AppColors.gray900,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          // 종목 심볼 (좌측)
          Text(
            widget.symbol,
            style: AppFonts.b1Semibold.copyWith(
              color: AppColors.gray900,
              fontSize: 18,
            ),
          ),
          const Spacer(),
          // 가격 정보 (우측)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _getCurrentPrice(),
                style: AppFonts.b1Semibold.copyWith(
                  color: AppColors.gray900,
                  fontSize: 14,
                ),
              ),
              Text(
                _getPriceChange(),
                style: AppFonts.b1Semibold.copyWith(
                  color: _getPriceChangeColor(),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getCurrentPrice() {
    return _currentPrice;
  }

  String _getPriceChange() {
    return _priceChange;
  }

  // 가격 정보 업데이트 메서드
  void updatePriceInfo(String price, String change) {
    setState(() {
      _currentPrice = price;
      _priceChange = change;
    });
  }

  Color _getPriceChangeColor() {
    final change = _getPriceChange();
    if (change.startsWith('+')) {
      return AppColors.loss; // 빨간색 (상승)
    } else if (change.startsWith('-')) {
      return AppColors.profit; // 파란색 (하락)
    }
    return AppColors.gray600;
  }
}