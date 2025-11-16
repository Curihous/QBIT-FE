import 'package:flutter/material.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:qbit_shared/widgets/common/header_basic.dart';
import 'package:qbit_shared/utils/responsive_utils.dart';
import 'package:qbit_services/api/learning_card_api_service.dart';
import 'package:qbit_services/models/learning_card_model.dart';
import 'package:qbit_services/auth/auth_service.dart';
import 'package:go_router/go_router.dart';

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  String _userNickname = '';
  
  // 추천 카드 (id=1, id=16)
  List<LearningCard> _recommendedCards = [];
  bool _isLoadingRecommended = false;
  
  // 레벨별 카드
  Map<int, List<LearningCard>> _levelCards = {};
  Map<int, bool> _isLoadingLevel = {};
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
      _loadRecommendedCards();
      _loadLevelCards();
    });
  }
  
  // 사용자 닉네임 가져오기
  Future<void> _loadUserData() async {
    try {
      final userInfo = await AuthService.getCurrentUser();
      if (!mounted) return;
      
      if (userInfo != null && userInfo['nickname'] != null) {
        setState(() {
          _userNickname = userInfo['nickname'] as String;
        });
      }
    } catch (error) {
      // 에러 무시
    }
  }
  
  // 추천 카드 로드 (id=1, id=16)
  Future<void> _loadRecommendedCards() async {
    setState(() {
      _isLoadingRecommended = true;
    });
    
    try {
      final response = await LearningCardApiService.getLearningCards();
      
      if (mounted) {
        if (response != null && response.success) {
          // id=1, id=16 필터링
          final filteredCards = response.cards
              .where((card) => card.id == 1 || card.id == 16)
              .toList();
          
          // 정렬: ID 1번이 먼저 오도록
          filteredCards.sort((a, b) {
            if (a.id == 1) return -1;
            if (b.id == 1) return 1;
            if (a.id == 16) return -1;
            if (b.id == 16) return 1;
            return 0;
          });
          
          setState(() {
            _recommendedCards = filteredCards.take(2).toList();
            _isLoadingRecommended = false;
          });
        } else {
          setState(() {
            _isLoadingRecommended = false;
          });
        }
      }
    } catch (e) {
      debugPrint('추천 카드 로드 실패: $e');
      if (mounted) {
        setState(() {
          _isLoadingRecommended = false;
        });
      }
    }
  }
  
  // 레벨별 카드 로드
  Future<void> _loadLevelCards() async {
    // Level 1, Level 2, Level 3 로드
    for (int level = 1; level <= 3; level++) {
      setState(() {
        _isLoadingLevel[level] = true;
      });
      
      try {
        final response = await LearningCardApiService.getLearningCards(
          level: level,
        );
        
        if (mounted) {
          if (response != null && response.success) {
            setState(() {
              _levelCards[level] = response.cards;
              _isLoadingLevel[level] = false;
            });
          } else {
            setState(() {
              _levelCards[level] = [];
              _isLoadingLevel[level] = false;
            });
          }
        }
      } catch (e) {
        debugPrint('레벨 $level 카드 로드 실패: $e');
        if (mounted) {
          setState(() {
            _levelCards[level] = [];
            _isLoadingLevel[level] = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: HeaderBasic(
        title: '이론 학습',
        onAlarmPressed: () {},
        onSettingPressed: () {},
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 노란색 배너: "큐빗님을 위한 추천"
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE19B),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: context.h(20)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: context.w(20)),
                    child: Text(
                      _userNickname.isNotEmpty 
                          ? '$_userNickname님을 위한 추천'
                          : '큐빗님을 위한 추천',
                      style: TextStyle(
                        color: const Color(0xFF323232),
                        fontSize: 18,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                        height: 1.17,
                      ),
                    ),
                  ),
                  SizedBox(height: context.h(16)),
                  // 추천 카드들 (가로 스크롤)
                  if (_isLoadingRecommended)
                    Container(
                      height: context.h(163),
                      padding: EdgeInsets.symmetric(horizontal: context.w(20)),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_recommendedCards.isEmpty)
                    Container(
                      height: context.h(163),
                      padding: EdgeInsets.symmetric(horizontal: context.w(20)),
                      child: Center(
                        child: Text(
                          '추천 카드가 없습니다',
                          style: AppFonts.b2Regular.copyWith(
                            color: AppColors.gray600,
                          ),
                        ),
                      ),
                    )
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: context.w(20)),
                      child: Row(
                        children: [
                          ..._recommendedCards.asMap().entries.map((entry) {
                            final index = entry.key;
                            final card = entry.value;
                            return Row(
                              children: [
                                _buildLearningCard(
                                  context,
                                  card: card,
                                  cardIndex: index, // 추천: image1, image2
                                  onTap: () {
                                    context.push('/learning-card/${card.category}', extra: card.keywordsList);
                                  },
                                ),
                                if (index < _recommendedCards.length - 1)
                                  SizedBox(width: context.w(16)),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  SizedBox(height: context.h(20)), // 하단 여백
                ],
              ),
            ),
            
            // 레벨별 학습 섹션
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.w(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: context.h(20)),
                  Text(
                    '레벨별 학습',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      height: 1.17,
                    ),
                  ),
                  
                  // Level 1
                  SizedBox(height: context.h(20)),
                  Text(
                    'Level 1',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  SizedBox(height: context.h(12)),
                  _buildLevelCards(context, level: 1),
                  
                  // Level 2
                  SizedBox(height: context.h(20)),
                  Text(
                    'Level 2',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  SizedBox(height: context.h(12)),
                  _buildLevelCards(context, level: 2),
                  
                  // Level 3
                  SizedBox(height: context.h(20)),
                  Text(
                    'Level 3',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  SizedBox(height: context.h(12)),
                  _buildLevelCards(context, level: 3),
                  
                  // 하단 여백
                  SizedBox(height: context.h(100)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // 레벨별 카드 위젯
  Widget _buildLevelCards(BuildContext context, {required int level}) {
    final cards = _levelCards[level] ?? [];
    final isLoading = _isLoadingLevel[level] ?? false;
    
    if (isLoading) {
      return Container(
        height: context.h(163),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (cards.isEmpty) {
      return Container(
        height: context.h(163),
        child: Center(
          child: Text(
            'Level $level 카드가 없습니다',
            style: AppFonts.b2Regular.copyWith(
              color: AppColors.gray600,
            ),
          ),
        ),
      );
    }
    
    // 각 레벨별로 시작 이미지 인덱스를 다르게 설정하여 골고루 사용
    // Level 1: image3부터 시작, Level 2: image5부터 시작, Level 3: image2부터 시작
    final startImageIndex = level == 1 ? 2 : (level == 2 ? 4 : 1);
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...cards.asMap().entries.map((entry) {
            final index = entry.key;
            final card = entry.value;
            // 각 레벨별 시작 인덱스 + 카드 인덱스를 더해서 5로 나눈 나머지
            final imageIndex = (startImageIndex + index) % 5;
            return Row(
              children: [
                _buildLearningCard(
                  context,
                  card: card,
                  cardIndex: imageIndex, // image1~image5 골고루 사용
                  onTap: () {
                    context.push('/learning-card/${card.category}', extra: card.keywordsList);
                  },
                ),
                if (index < cards.length - 1)
                  SizedBox(width: context.w(16)),
              ],
            );
          }),
        ],
      ),
    );
  }
  
  // 학습 카드 위젯 (홈화면과 동일)
  Widget _buildLearningCard(
    BuildContext context, {
    LearningCard? card,
    String? title,
    String? tag,
    required VoidCallback onTap,
    int? cardIndex,
  }) {
    final cardTitle = card?.title ?? title ?? '제목 제목 제목';
    final cardTag = card != null 
        ? '#${card.category}'
        : (tag ?? '#태그태그');
    
    // 카드 인덱스에 따라 이미지 경로 결정 (0: image1.png, 1: image2.png, ...)
    final imagePath = cardIndex != null 
        ? 'assets/cards/image${(cardIndex % 5) + 1}.png'
        : 'assets/cards/image1.png';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: context.w(234),
        height: context.h(163),
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Stack(
          children: [
            // 배경 이미지
            Positioned(
              left: 0,
              top: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  imagePath,
                  width: context.w(234),
                  height: context.h(163),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: context.w(234),
                      height: context.h(163),
                      decoration: ShapeDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment(0.50, -0.00),
                          end: Alignment(0.50, 1.00),
                          colors: [Color(0xFFD9D9D9), Color(0xFF737373)],
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // 그라데이션 오버레이
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: context.w(234),
                height: context.h(163),
                decoration: ShapeDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.6),
                    ],
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            // 제목
            Positioned(
              left: context.w(13),
              top: context.h(92),
              child: Text(
                cardTitle,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ),
            // 태그
            Positioned(
              left: context.w(13),
              top: context.h(127),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: ShapeDecoration(
                  color: const Color(0xFFE6F4F1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                child: Text(
                  cardTag,
                  style: TextStyle(
                    color: const Color(0xFF323232),
                    fontSize: 13,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                    height: 1.23,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
