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
import 'package:kakao_flutter_sdk_auth/kakao_flutter_sdk_auth.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

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

  @override
  void initState() {
    super.initState();
    // 비동기 작업을 안전하게 실행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocaleAndSetDate();
      _loadUserData();
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
            Container(
              width: double.infinity,
              height: 276,
              decoration: const BoxDecoration(
                color: AppColors.secondaryMain, // 노란색 배경
              ),
              child: Stack(
                children: [
                  // 제목
                  Positioned(
                    left: 20,
                    top: 25,
                    child: Text(
                      _userNickname.isNotEmpty 
                        ? '$_currentDate, $_userNickname님을 위한 소식'
                        : '$_currentDate, 큐빗을 위한 소식',
                      style: AppFonts.t2Bold.copyWith(
                        color: AppColors.gray900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 추천 이론 학습 섹션 (구현 예정)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '추천 이론 학습',
                    style: AppFonts.t2Semibold.copyWith(
                      color: AppColors.gray900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '구현 예정',
                        style: AppFonts.b1Regular.copyWith(
                          color: AppColors.gray400,
                        ),
                      ),
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
