import 'package:flutter/material.dart';
import 'package:qbit_shared/widgets/common/bottom_navigation_bar.dart';
import 'package:qbit_shared/widgets/common/header_home.dart';
import 'package:qbit_shared/screens/study/study_screen.dart';
import 'package:qbit_shared/screens/record/record_screen.dart';
import 'package:qbit_shared/screens/trade/trade_screen.dart';
import 'package:qbit_shared/screens/my/my_screen.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/theme/app_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:qbit_services/auth/auth_service.dart';
import 'package:qbit_services/storage/token_service.dart';
import 'package:qbit_services/api/ai_api_service.dart';
import 'package:qbit_services/api/stock_api_service.dart';
import 'package:qbit_services/models/recommend_column_response.dart';
import 'package:qbit_services/models/column.dart' as models;
import 'package:kakao_flutter_sdk_auth/kakao_flutter_sdk_auth.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:qbit_shared/utils/responsive_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeContentScreen(),
    const StudyScreen(),
    const RecordScreen(),
    const TradeScreen(),
    const MyScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _screens[_currentIndex],
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomBottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

class HomeContentScreen extends StatefulWidget {
  const HomeContentScreen({super.key});

  @override
  State<HomeContentScreen> createState() => _HomeContentScreenState();
}

class _HomeContentScreenState extends State<HomeContentScreen> {
  String _userNickname = '';
  String _currentDate = '';
  RecommendColumnResponse? _columnResponse;
  bool _isLoadingColumn = false;
  String? _columnError;

  @override
  void initState() {
    super.initState();
    // 비동기 작업을 안전하게 실행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocaleAndSetDate();
      _loadUserData();
      _loadColumn();
      _printTokens();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  // 로케일 초기화 및 현재 날짜 설정
  Future<void> _initializeLocaleAndSetDate() async {
    try {
      await initializeDateFormatting('ko_KR', null);
      if (mounted) {
        _setCurrentDate();
      }
    } catch (e) {
      // 로케일 초기화 실패 시 기본 형식 사용
      if (mounted) {
        _setCurrentDateWithDefaultFormat();
      }
    }
  }

  // 현재 날짜 설정 (한국어 로케일)
  void _setCurrentDate() {
    if (!mounted) return;
    final now = DateTime.now();
    final formatter = DateFormat('M월 d일', 'ko_KR');
    setState(() {
      _currentDate = formatter.format(now);
    });
  }

  // 현재 날짜 설정 (기본 형식)
  void _setCurrentDateWithDefaultFormat() {
    if (!mounted) return;
    final now = DateTime.now();
    setState(() {
      _currentDate = '${now.month}월 ${now.day}일';
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
      } else {
        setState(() {
          _userNickname = '';
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _userNickname = '';
      });
    }
  }

  // 칼럼 추천 로드
  Future<void> _loadColumn() async {
    setState(() {
      _isLoadingColumn = true;
      _columnError = null;
    });

    try {
      // 사용자 포트폴리오 종목 가져오기
      debugPrint('📰 포트폴리오 종목 조회 시작...');
      final positions = await StockApiService.getPositions();
      final tickers = positions ?? <String>[];
      
      debugPrint('📰 포트폴리오 종목 조회 결과:');
      debugPrint('  - positions: $positions');
      debugPrint('  - tickers: $tickers');
      debugPrint('  - tickers.length: ${tickers.length}');
      
      if (tickers.isEmpty) {
        debugPrint('⚠️ 보유 종목이 없습니다. 인기 칼럼을 반환할 수 있습니다.');
      }
      
      // 상위 3개 종목만 사용 (API 권장사항)
      final topTickers = tickers.take(3).toList();
      
      debugPrint('📰 칼럼 추천 요청 시작:');
      debugPrint('  - 전체 보유 종목: $tickers');
      debugPrint('  - 사용할 종목 (상위 3개): $topTickers');
      debugPrint('  - 전송할 ticker 개수: ${topTickers.length}');
      
      final response = await AiApiService.recommendColumn(topTickers);
      
      debugPrint('📰 칼럼 추천 응답:');
      debugPrint('  - success: ${response.success}');
      debugPrint('  - source: ${response.source}');
      debugPrint('  - message: ${response.message}');
      debugPrint('  - ticker: ${response.column.ticker}');
      debugPrint('  - title: ${response.column.title}');
      debugPrint('  - subtitle: ${response.column.subtitle}');
      
      if (mounted) {
        setState(() {
          _columnResponse = response;
          _isLoadingColumn = false;
        });
      }
    } on ApiException catch (e) {
      debugPrint('📰 칼럼 추천 에러: ${e.message}');
      if (mounted) {
        setState(() {
          _columnError = e.message;
          _isLoadingColumn = false;
        });
      }
    } catch (e) {
      debugPrint('📰 칼럼 추천 예외: $e');
      if (mounted) {
        setState(() {
          _columnError = '칼럼을 불러오는 중 오류가 발생했습니다.';
          _isLoadingColumn = false;
        });
      }
    }
  }

  // 토큰 정보 출력
  Future<void> _printTokens() async {
    debugPrint('=== 토큰 정보 ===');
    
    // 백엔드 액세스 토큰
    final backendToken = await TokenService.getAccessToken();
    if (backendToken != null) {
      debugPrint('🔑 백엔드 액세스 토큰: $backendToken');
    } else {
      debugPrint('❌ 백엔드 액세스 토큰: 없음');
    }
    
    // 카카오 액세스 토큰 (SDK에서 직접)
    try {
      final kakaoToken = await TokenManagerProvider.instance.manager.getToken();
      if (kakaoToken?.accessToken != null) {
        debugPrint('🔑 카카오 액세스 토큰: ${kakaoToken!.accessToken}');
      } else {
        debugPrint('❌ 카카오 액세스 토큰: 없음');
      }
    } catch (e) {
      debugPrint('❌ 카카오 액세스 토큰 조회 실패: $e');
    }
    
    // 저장된 카카오 토큰
    final storedKakaoToken = await TokenService.getKakaoAccessToken();
    if (storedKakaoToken != null) {
      debugPrint('🔑 저장된 카카오 토큰: $storedKakaoToken');
    } else {
      debugPrint('❌ 저장된 카카오 토큰: 없음');
    }
    
    debugPrint('================');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const TopAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 사용자를 위한 소식 섹션
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.w(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: context.h(12)),
                  // 상단 배너 (11월 16일, user nickname님을 위한 소식)
                  Container(
                    width: double.infinity,
                    height: context.h(48),
                    decoration: ShapeDecoration(
                      color: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 0.50,
                          color: AppColors.gray150,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: context.w(16)),
                      child: Row(
                        children: [
                          Text(
                            '🗞️',
                            style: TextStyle(
                              fontSize: context.w(16),
                            ),
                          ),
                          SizedBox(width: context.w(8)),
                          Expanded(
                            child: Text(
                              _userNickname.isNotEmpty 
                                ? '$_currentDate, $_userNickname님을 위한 소식'
                                : '$_currentDate, 큐빗을 위한 소식',
                              style: AppFonts.b1Semibold.copyWith(
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: context.h(12)),
                  
                  // 칼럼 카드
                  if (_isLoadingColumn)
                    Container(
                      width: double.infinity,
                      height: context.h(203), // 137 + 66
                      decoration: BoxDecoration(
                        color: AppColors.gray100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_columnError != null)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(context.w(16)),
                      decoration: BoxDecoration(
                        color: AppColors.gray100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _columnError!,
                            style: AppFonts.b1Regular.copyWith(
                              color: AppColors.gray600,
                            ),
                          ),
                          SizedBox(height: context.h(8)),
                          TextButton(
                            onPressed: _loadColumn,
                            child: const Text('다시 시도'),
                          ),
                        ],
                      ),
                    )
                  else if (_columnResponse != null)
                    _buildColumnCard(_columnResponse!.column as models.Column),
                ],
              ),
            ),
            // 추천 이론 학습 섹션
            SizedBox(height: context.h(20)),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: context.w(20), vertical: context.h(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 헤더: 제목 + 더 학습하기 링크
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '추천 이론 학습',
                        style: AppFonts.t2Semibold.copyWith(
                          color: AppColors.gray900,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // TODO: 더 학습하기 화면으로 이동
                        },
                        child: Row(
                          children: [
                            Text(
                              '더 학습하기',
                              style: AppFonts.b2Regular.copyWith(
                                color: AppColors.gray600,
                              ),
                            ),
                            SizedBox(width: context.w(4)),
                            Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: AppColors.gray600,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.h(16)),
                  
                  // 학습 카드들 (2개 가로 배치)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildLearningCard(
                          context,
                          title: '제목 제목 제목',
                          tag: '#태그태그',
                          onTap: () {
                            // TODO: 학습 카드 상세로 이동
                          },
                        ),
                        SizedBox(width: context.w(16)),
                        _buildLearningCard(
                          context,
                          title: '제목 제목 제목',
                          tag: '#태그태그',
                          onTap: () {
                            // TODO: 학습 카드 상세로 이동
                          },
                        ),
                      ],
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

  Widget _buildColumnCard(models.Column column) {
    return GestureDetector(
      onTap: () {
        // 칼럼 상세 화면으로 이동
        context.pushNamed(
          'column-detail',
          pathParameters: {'ticker': column.ticker},
        );
      },
      child: Column(
        children: [
          // 이미지 (상단만 radius 12)
          if (column.imageUrl != null && column.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Image.network(
                column.imageUrl!,
                width: double.infinity,
                height: context.h(137),
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: double.infinity,
                    height: context.h(137),
                    color: AppColors.gray100,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  width: double.infinity,
                  height: context.h(137),
                  color: AppColors.gray100,
                  child: Icon(
                    Icons.error_outline,
                    color: AppColors.gray400,
                    size: context.w(40),
                  ),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              height: context.h(137),
              decoration: const BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Icon(
                Icons.image_not_supported,
                color: AppColors.gray400,
                size: context.w(40),
              ),
            ),
          
          // 하단 정보 (하단만 radius 10, 높이 66)
          Container(
            width: double.infinity,
            height: context.h(66),
            padding: EdgeInsets.symmetric(
              horizontal: context.w(16),
              vertical: context.h(12),
            ),
            decoration: ShapeDecoration(
              color: AppColors.gray50,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: 0.50,
                  color: AppColors.gray150,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 제목
                Text(
                  column.title,
                  style: AppFonts.b1Semibold.copyWith(
                    color: AppColors.gray900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: context.h(2)),
                // 부제 ∙ 심볼
                Text(
                  column.subtitle != null && column.subtitle!.isNotEmpty && column.ticker.isNotEmpty
                      ? '${column.subtitle} ∙ ${column.ticker}'
                      : column.subtitle != null && column.subtitle!.isNotEmpty
                          ? column.subtitle!
                          : column.ticker.isNotEmpty
                              ? column.ticker
                              : '',
                  style: AppFonts.b2Regular.copyWith(
                    color: AppColors.gray600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 학습 카드 위젯
  Widget _buildLearningCard(
    BuildContext context, {
    required String title,
    required String tag,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Stack(
          children: [
            Positioned(
              left: context.w(16),
              top: context.h(92),
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ),
            Positioned(
              left: context.w(16),
              top: context.h(127),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    color: Colors.black,
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
