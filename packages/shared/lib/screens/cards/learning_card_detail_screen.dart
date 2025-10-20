import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/common/header_back.dart';

class LearningCardDetailScreen extends StatefulWidget {
  final String cardType;
  
  const LearningCardDetailScreen({
    super.key,
    required this.cardType,
  });

  @override
  State<LearningCardDetailScreen> createState() => _LearningCardDetailScreenState();
}

class _LearningCardDetailScreenState extends State<LearningCardDetailScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  final int _totalPages = 5; // title + 4 pages

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7), // Gray-30
      appBar: HeaderBack(
        title: '',
        backgroundColor: const Color(0xFFF7F7F7), // Gray-30
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // PageView for card content
            Positioned(
              left: 16,
              top: 80,
              child: Container(
                width: 360,
                height: 450,
                clipBehavior: Clip.antiAlias,
                decoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  shadows: [
                    BoxShadow(
                      color: Color(0x1E000000),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                      spreadRadius: 0,
                    )
                  ],
                ),
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  children: [
                    // Title page
                    Image.asset(
                      'assets/cards/title.png',
                      fit: BoxFit.cover,
                    ),
                    // Content pages
                    Image.asset(
                      'assets/cards/1.png',
                      fit: BoxFit.cover,
                    ),
                    Image.asset(
                      'assets/cards/2.png',
                      fit: BoxFit.cover,
                    ),
                    Image.asset(
                      'assets/cards/3.png',
                      fit: BoxFit.cover,
                    ),
                    Image.asset(
                      'assets/cards/4.png',
                      fit: BoxFit.cover,
                    ),
                  ],
                ),
              ),
            ),
            
            // 카테고리 태그
            Positioned(
              left: 16,
              top: 40,
              child: Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: ShapeDecoration(
                  color: const Color(0xFF04B99A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _getCategoryTag(widget.cardType),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w400,
                        height: 1.23,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // 페이지 인디케이터
            Positioned(
              left: 171,
              top: 550,
              child: Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: ShapeDecoration(
                  color: const Color(0xFFD1D5DB), // Gray-300
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '${_currentPage + 1}/$_totalPages',
                      style: TextStyle(
                        color: const Color(0xFF323232), // Gray-900
                        fontSize: 13,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w400,
                        height: 1.23,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryTag(String cardType) {
    switch (cardType) {
      case 'risk_management':
        return '#리스크관리';
      case 'investment_psychology':
        return '#투자심리';
      default:
        return '#학습';
    }
  }
}
