import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:qbit_shared/widgets/common/header/header_back.dart';
import 'package:qbit_shared/layout/horizontal_inset.dart';
import 'package:qbit_services/models/learning_card_model.dart';
import '../../utils/responsive_utils.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';

class LearningCardDetailScreen extends StatefulWidget {
  final LearningCard? card; // LearningCard 객체
  final String cardType;
  final List<String>? extractedTags; // AI 리포트에서 추출된 태그들
  
  const LearningCardDetailScreen({
    super.key,
    this.card,
    required this.cardType,
    this.extractedTags,
  });

  @override
  State<LearningCardDetailScreen> createState() => _LearningCardDetailScreenState();
}

class _LearningCardDetailScreenState extends State<LearningCardDetailScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  List<Widget>? _cachedCardPages;
  
  int get _totalPages {
    // 캐시된 페이지가 있으면 사용, 없으면 생성
    _cachedCardPages ??= _buildCardPages();
    return _cachedCardPages!.length;
  }
  
  @override
  void didUpdateWidget(LearningCardDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 카드가 변경되면 캐시 무효화
    if (oldWidget.card?.id != widget.card?.id) {
      _cachedCardPages = null;
    }
  }

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
      backgroundColor: AppColors.gray30,
      appBar: HeaderBack(
        title: '학습 카드',
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 80,
              child: Center(
                child: Container(
                  width: 360,
                  height: 450,
                  clipBehavior: Clip.antiAlias,
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                    ),
                    shadows: AppShadows.main,
                  ),
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    children: _cachedCardPages ?? _buildCardPages(),
                  ),
                ),
              ),
            ),
            
            // 페이지 인디케이터
            Positioned(
              left: 0,
              right: 0,
              top: 550,
              child: Center(
                child: Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  decoration: ShapeDecoration(
                    color: AppColors.gray200,
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
                        style: AppFonts.c1.copyWith(
                          color: AppColors.gray900,
                          height: 1.23,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 카드 페이지들을 동적으로 생성
  List<Widget> _buildCardPages() {
    final card = widget.card;
    
    if (card != null) {
      final pages = _getCardImagePaths(card.id);
      _cachedCardPages = pages;
      return pages;
    }
    
    final pages = _getDefaultImagePaths();
    _cachedCardPages = pages;
    return pages;
  }
  
  /// 카드 ID 기반 이미지 경로 반환
  List<Widget> _getCardImagePaths(int cardId) {
    final widgets = <Widget>[];
    
    // 타이틀 이미지
    widgets.add(Image.asset(
      'assets/cards/card_${cardId}_title.png',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildErrorWidget(),
    ));
    
    // 본문 이미지들 (고정 6개)
    for (int i = 1; i <= 6; i++) {
      widgets.add(Image.asset(
        'assets/cards/card_${cardId}_$i.png',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildErrorWidget(),
      ));
    }
    
    return widgets;
  }
  
  /// 기본 이미지 경로 반환
  List<Widget> _getDefaultImagePaths() {
    return ['title', '1', '2', '3', '4'].map((name) {
      return Image.asset(
        'assets/cards/$name.png',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildErrorWidget(),
      );
    }).toList();
  }
  
  /// 에러 위젯 빌드
  Widget _buildErrorWidget() {
    return Container(
      color: AppColors.gray300,
      child: Center(
        child: Text(
          '이미지를 불러올 수 없습니다',
          style: AppFonts.b1Regular.copyWith(
            color: AppColors.gray600,
          ),
        ),
      ),
    );
  }

  /// 카테고리 태그 반환
  String _getCategoryTag() {
    final category = widget.card?.category ?? widget.cardType;
    
    switch (category) {
      case 'risk_management':
        return '#리스크관리';
      case 'investment_psychology':
        return '#투자심리';
      case 'technical_analysis':
        return '#기술적분석';
      case 'basic_strategy':
        return '#투자전략';
      case 'market_analysis':
        return '#시장분석';
      default:
        return '#학습';
    }
  }
}
