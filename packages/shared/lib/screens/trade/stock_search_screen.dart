import 'package:flutter/material.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_services/api/stock_api_service.dart';
import 'package:qbit_services/models/stock_model.dart';
import 'package:qbit_shared/screens/trade/stock_detail_screen.dart';

// 종목 검색 화면
class StockSearchScreen extends StatefulWidget {
  final String? symbol;
  
  const StockSearchScreen({super.key, this.symbol});

  @override
  State<StockSearchScreen> createState() => _StockSearchScreenState();
}

class _StockSearchScreenState extends State<StockSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<StockModel> _searchResults = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // URL 파라미터로 전달된 symbol이 있으면 검색 실행
    if (widget.symbol != null && widget.symbol!.isNotEmpty) {
      _searchController.text = widget.symbol!;
      _searchStocks(widget.symbol!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchStocks(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await StockApiService.searchStocks(query.trim());
      if (mounted) {
        setState(() {
          _searchResults = results ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.gray900,
        elevation: 0,
        title: Text(
          '종목 검색',
          style: AppFonts.titleLarge.copyWith(color: AppColors.gray900),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
        // 검색 입력 필드
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            width: 361,
            height: 48,
            padding: const EdgeInsets.all(2),
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: 1,
                  color: AppColors.gray300, // Gray-300
                ),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.search,
                    color: AppColors.gray600, // Gray-600
                    size: 20,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '종목을 입력하세요',
                      hintStyle: AppFonts.bodyLarge.copyWith(
                        color: AppColors.gray600, // Gray-600
                        height: 1.40,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: AppFonts.bodyLarge.copyWith(
                      color: AppColors.gray900, // Gray-900
                      height: 1.40,
                    ),
                    onChanged: (value) {
                      setState(() {});
                      if (value.length >= 2) {
                        _searchStocks(value);
                      } else {
                        setState(() {
                          _searchResults = [];
                          _error = null;
                        });
                      }
                    },
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  Container(
                    width: 36,
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    child: IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: AppColors.gray600, // Gray-600
                        size: 24,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults = [];
                          _error = null;
                        });
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
          
          // 검색 결과
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('검색 중 오류가 발생했습니다: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _searchStocks(_searchController.text),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }
    
    if (_searchResults.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.isEmpty 
              ? '종목명 또는 종목코드를 입력해주세요'
              : '검색 결과가 없습니다',
          style: AppFonts.bodyMedium.copyWith(color: AppColors.gray600),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final stock = _searchResults[index];
        return _buildStockItem(stock);
      },
    );
  }

  Widget _buildStockItem(StockModel stock) {
    return Container(
      width: double.infinity,
      height: 58,
      margin: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          print('종목 탭됨: ${stock.symbol} - ${stock.name}');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StockDetailScreen(
                symbol: stock.symbol,
                name: stock.name,
              ),
            ),
          );
        },
        child: Stack(
          children: [
            Positioned(
              left: 16,
              top: 6,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 9,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: ShapeDecoration(
                      color: AppColors.warning.withOpacity(0.1), // Secondary-soft
                      shape: OvalBorder(),
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: stock.name.contains('Apple') ? 'Apple' : stock.name.split(' ').first,
                          style: AppFonts.bodyLarge.copyWith(
                            color: AppColors.primaryDark, // Primary-Font
                            height: 1.40,
                          ),
                        ),
                        TextSpan(
                          text: stock.name.contains('Apple') 
                              ? ' Inc. Common Stock' 
                              : stock.name.substring(stock.name.contains('Apple') ? 5 : stock.name.split(' ').first.length),
                          style: AppFonts.bodyLarge.copyWith(
                            color: AppColors.gray900, // Gray-900(Font-Black)
                            height: 1.40,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    stock.symbol,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.gray600, // Gray-600
                      fontSize: 14,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w400,
                      height: 1.71,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}