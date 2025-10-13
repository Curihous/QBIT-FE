import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dio/dio.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/common_widgets.dart';
import 'alpaca_auth_screen.dart';
import 'stock_search_screen.dart';
import 'package:qbit_services/auth/kakao_auth_service.dart';
import 'package:qbit_services/auth/alpaca_auth_service.dart';
import 'package:qbit_services/auth/auth_service.dart';
import 'package:qbit_services/api/stock_api_service.dart';
import 'package:qbit_services/models/stock_model.dart';
import 'package:qbit_services/models/asset_model.dart';
import 'package:qbit_services/models/stock_ranking_model.dart';
import 'package:qbit_services/storage/token_service.dart';
import 'package:qbit_services/api/api_client.dart';

class TradeScreen extends StatefulWidget {
  const TradeScreen({super.key});

  @override
  State<TradeScreen> createState() => _TradeScreenState();
}

class _TradeScreenState extends State<TradeScreen> {
  // Derive the selected tab index from the current GoRouter location
  int _getCurrentIndex() {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/learning')) return 1;
    if (location.startsWith('/record')) return 2;
    if (location.startsWith('/trade')) return 3;
    if (location.startsWith('/analysis')) return 4;
    return 0;
  }
  bool _isAlpacaConnected = false; // Alpaca 연동 상태 - 강제로 false로 설정
  
  String _userNickname = ''; // 카카오 닉네임
  List<StockModel> _overseasIndices = []; // 해외 주요 지수 데이터
  AssetModel? _userAssets; // 보유자산 데이터
  List<StockRankingModel> _stockRanking = []; // 해외 종목 순위 데이터
  String _selectedSortBy = 'volume'; // 선택된 정렬 기준
  int? _selectedStockIndex; // 선택된 종목 인덱스
  
  StreamSubscription<void>? _tokenExpiredSubscription;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    
    // 토큰 만료 이벤트 구독
    _tokenExpiredSubscription = ApiClient.onTokenExpired.listen((_) {
      _handleTokenExpired();
    });
    
    // Alpaca 연동 성공 콜백 설정
    AlpacaAuthScreen.onSuccess = () async {
      // Alpaca Allow 후 연결 완료 간주 
      if (mounted) {
        setState(() {
          _isAlpacaConnected = true;
        });
      }
      _loadUserAssets(); // 연동 후 자산 데이터 다시 로드
    };
  }

  // 사용자 데이터 로드
  Future<void> _loadUserData() async {
    await _loadKakaoNickname();
    await _loadOverseasIndices();
    await _checkAlpacaConnectionStatus();
    await _loadUserAssets();
    await _loadStockRanking(); 
  }

  // Alpaca 연결 상태 확인
  Future<void> _checkAlpacaConnectionStatus() async {
    try {
      // 먼저 로그인 상태 확인
      final isLoggedIn = await TokenService.isLoggedIn();
      
      if (!isLoggedIn) {
        if (mounted) {
          setState(() {
            _isAlpacaConnected = false;
          });
        }
        return;
      }
      

      // Alpaca 계정 정보로 연결 상태 확인
      final accountInfo = await StockApiService.getAlpacaAccount();
      if (mounted) {
        setState(() {
          _isAlpacaConnected = accountInfo != null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isAlpacaConnected = false;
        });
      }
    }
  }

  // 토큰 만료 처리
  void _handleTokenExpired() {
    if (mounted) {
      // 로그인 페이지로 이동
      context.go('/login');
    }
  }

  // 사용자 닉네임 가져오기 (백엔드 users/me 엔드포인트 사용)
  Future<void> _loadKakaoNickname() async {
    try {
      // 백엔드에서 사용자 정보 가져오기
      final userInfo = await AuthService.getCurrentUser();
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
      setState(() {
        _userNickname = '';
      });
    }
  }

  // 보유자산 데이터 가져오기
  Future<void> _loadUserAssets() async {
    try {
      final assets = await StockApiService.getUserAssets();
      if (mounted) {
        setState(() {
          _userAssets = assets;
        });
      }
    } catch (error) {
      // Alpaca 연결이 안 된 경우 null로 설정
      setState(() {
        _userAssets = null;
      });
    }
  }

  // 해외 종목 순위 데이터 가져오기 (하드코딩 데이터)
  Future<void> _loadStockRanking() async {
    // API 연동은 주석 처리하고 하드코딩된 데이터 사용
    setState(() {
      _stockRanking = _getDefaultStockRanking();
    });
    
    // TODO: 실제 API 연동 시 아래 코드 활성화
    /*
    try {
      final ranking = await StockApiService.getOverseasStockRanking(sortBy: _selectedSortBy);
      if (mounted) {
        setState(() {
          _stockRanking = ranking ?? [];
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _stockRanking = _getDefaultStockRanking();
        });
      }
    }
    */
  }

  // 기본 종목 순위 데이터
  List<StockRankingModel> _getDefaultStockRanking() {
    return [
      StockRankingModel(
        rank: 1,
        symbol: 'STOCK1',
        name: '종목명',
        price: 0.0, // 가격
        changeAmount: 0.0,
        changePercentage: 0.0, // 수익률
        isPositive: true,
      ),
      StockRankingModel(
        rank: 2,
        symbol: 'STOCK2',
        name: '종목명',
        price: 0.0, // 가격
        changeAmount: 0.0,
        changePercentage: 0.0, // 수익률
        isPositive: true,
        isHighlighted: true,
      ),
      StockRankingModel(
        rank: 3,
        symbol: 'STOCK3',
        name: '종목명',
        price: 0.0, // 가격
        changeAmount: 0.0,
        changePercentage: 0.0, // 수익률
        isPositive: true,
      ),
      StockRankingModel(
        rank: 4,
        symbol: 'STOCK4',
        name: '종목명',
        price: 0.0, // 가격
        changeAmount: 0.0,
        changePercentage: 0.0, // 수익률
        isPositive: true,
      ),
      StockRankingModel(
        rank: 5,
        symbol: 'STOCK5',
        name: '종목명',
        price: 0.0, // 가격
        changeAmount: 0.0,
        changePercentage: 0.0, // 수익률
        isPositive: true,
      ),
      StockRankingModel(
        rank: 6,
        symbol: 'STOCK6',
        name: '종목명',
        price: 0.0, // 가격
        changeAmount: 0.0,
        changePercentage: 0.0, // 수익률
        isPositive: true,
      ),
      StockRankingModel(
        rank: 7,
        symbol: 'STOCK7',
        name: '종목명',
        price: 0.0, // 가격
        changeAmount: 0.0,
        changePercentage: 0.0, // 수익률
        isPositive: true,
      ),
    ];
  }

  // 해외 주요 지수 데이터 가져오기
  Future<void> _loadOverseasIndices() async {
    try {
      final indices = await StockApiService.getOverseasIndices();
      
      if (indices != null && indices.isNotEmpty) {
        // S&P 500과 NASDAQ만 필터링
        final filteredIndices = indices.where((index) {
          final symbol = index.symbol.toUpperCase();
          final name = index.name.toUpperCase();
          return symbol.contains('SPX') || symbol.contains('GSPC') || 
                 symbol.contains('NASDAQ') || symbol.contains('IXIC') ||
                 name.contains('S&P') || name.contains('NASDAQ');
        }).toList();
        
        setState(() {
          _overseasIndices = filteredIndices;
        });
      } else {
        _setDefaultIndices();
      }
    } catch (error) {
      // 토큰 만료나 인증 오류와 관계없이 항상 기본 데이터 표시
      _setDefaultIndices();
    }
  }

  // 수익률 계산 (Infinity 방지)
  String _calculateReturnPercentage() {
    final equity = _userAssets?.equity ?? 100500;
    final lastEquity = _userAssets?.lastEquity ?? 100000;
    
    // lastEquity가 0이거나 매우 작으면 수익률을 0으로 처리
    if (lastEquity <= 0) {
      return '0.0';
    }
    
    final changeAmount = equity - lastEquity;
    final changePercentage = (changeAmount / lastEquity) * 100;
    
    // Infinity나 NaN 체크
    if (changePercentage.isInfinite || changePercentage.isNaN) {
      return '0.0';
    }
    
    // 매우 큰 값이나 작은 값 체크 (예: ±1000% 이상)
    if (changePercentage.abs() > 1000) {
      return changeAmount > 0 ? '+999.9' : '-999.9';
    }
    
    final sign = changeAmount > 0 ? '+' : '';
    return '$sign${changePercentage.toStringAsFixed(1)}';
  }

  // 기본 지수 데이터 설정 (API 실패 시에만 사용)
  void _setDefaultIndices() {
    
    // 실제 지표 데이터로 폴백 (토큰 만료 시에도 사용자에게 유용한 정보 제공)
    final defaultIndices = <StockModel>[
      StockModel(
        symbol: 'SPX',
        name: 'S&P 500',
        currentPrice: 5473.23,
        changeAmount: 12.45,
        changePercentage: 0.23,
        isPositive: true,
      ),
      StockModel(
        symbol: 'IXIC',
        name: 'NASDAQ',
        currentPrice: 17857.02,
        changeAmount: -23.67,
        changePercentage: -0.13,
        isPositive: false,
      ),
    ];
    
    setState(() {
      _overseasIndices = defaultIndices;
    });
  }


  // 하단 네비
  void _onNavItemTap(int index) {
    switch (index) {
      case 0:
        // 홈
        context.go('/home');
        break;
      case 1:
        // 학습
        context.go('/learning');
        break;
      case 2:
        // 기록
        context.go('/record');
        break;
      case 3:
        // 거래 (현재)
        break;
      case 4:
        // 분석
        context.go('/analysis');
        break;
    }
  }

  // 계좌 연결하기 버튼 클릭
  void _onConnectAccount() {
    // 연동 성공 콜백 설정
    AlpacaAuthScreen.onSuccess = () {
        setState(() {
        _isAlpacaConnected = true;
      });
    };
    
    // Alpaca 동의 화면으로 이동
    context.push('/alpaca-auth');
  }


  // 계좌 정보 위젯 (연동 상태에 따라 블러 처리)
  Widget _buildAccountSection() {
    return Stack(
                  children: [
        // 기본 계좌 정보
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(
              children: [
                        if (_userNickname.isNotEmpty) ...[
                          TextSpan(
                            text: _userNickname,
                            style: AppFonts.bodyLarge.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextSpan(
                            text: '님의 보유자산',
                            style: AppFonts.bodyLarge.copyWith(
                              color: AppColors.gray900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ] else ...[
                          TextSpan(
                            text: '보유자산',
                        style: AppFonts.bodyLarge.copyWith(
                              color: AppColors.gray900,
                              fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // 상세보기 기능
                    },
                    child: Text(
                      '상세보기',
                      style: AppFonts.captionLargeRegular.copyWith(color: AppColors.gray600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 실제 보유자산 금액 (API 연동 후 실제 데이터로 교체)
              Text(
                '\$ 50,400,500',
                style: AppFonts.titleLarge.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray900,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Container(),
              ),
            ],
          ),
        ),
        
        // 연동되지 않은 경우 블러 오버레이와 연동 버튼
        if (!_isAlpacaConnected)
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withOpacity(0.8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance,
                          size: 48,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Alpaca 계좌를 연동해주세요',
                          style: AppFonts.titleMedium.copyWith(
                            color: AppColors.gray900,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '실시간 거래 정보를 확인하세요',
                          style: AppFonts.bodyMedium.copyWith(
                            color: AppColors.gray600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _onConnectAccount,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            '계좌 연동하기',
                            style: AppFonts.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }


  // 검색바 섹션
  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const StockSearchScreen(),
            ),
          );
        },
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
              SizedBox(
                width: 224,
                child: Text(
                  '종목을 입력하세요',
                  style: AppFonts.bodyLarge.copyWith(
                    color: AppColors.gray600, // Gray-600
                    height: 1.40,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 보유자산 섹션
  Widget _buildAssetSection() {
    if (_isAlpacaConnected) {
      // Alpaca 연동 후 - 실제 자산 정보 표시
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.only(bottom: 9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 352,
                    height: 50,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          top: 0,
                          child: Container(
                            width: 172,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 2,
                              children: [
                                SizedBox(
                                  width: 172,
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: _userNickname.isNotEmpty ? _userNickname : '큐빗',
                                          style: AppFonts.bodyLargeBold.copyWith(color: AppColors.primary),
                                        ),
                                        TextSpan(
                                          text: '님의 보유자산',
                                          style: AppFonts.bodyLargeSemiBold.copyWith(color: AppColors.gray900),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 172,
                                  child: Text(
                                    '\$ ${(_userAssets?.portfolioValue ?? 100500).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                                    style: AppFonts.titleMedium.copyWith(color: AppColors.gray900),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 303,
                          top: 26,
                          child: Text(
                            '상세보기',
                            textAlign: TextAlign.center,
                            style: AppFonts.captionLargeSemiBold.copyWith(color: AppColors.gray600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 359,
              height: 125,
              decoration: ShapeDecoration(
                color: Colors.white /* Gray-0 */,
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    width: 1,
                    color: AppColors.gray300, /* Gray-300 */
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Stack(
                children: [
                  // Alpaca 연동 후 - 실제 차트와 데이터 표시
                  Positioned(
                    left: 16,
                    top: 16,
                    right: 16,
                    bottom: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.background.withOpacity(0.3),
                            AppColors.background.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  // 수익률 표시 (카드 내부)
                  Positioned(
                    right: 16,
                    top: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: ShapeDecoration(
                        color: AppColors.secondaryMain,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      child: Text(
                        '${_calculateReturnPercentage()}%',
                                    style: AppFonts.captionSmallRegular.copyWith(color: AppColors.gray900),
                      ),
                    ),
                  ),
                  // 기간 표시 (카드 내부)
                  Positioned(
                    left: 16,
                    bottom: 16,
                    child: Text(
                      'Today',
                                    style: AppFonts.captionSmallRegular.copyWith(color: AppColors.gray900),
                    ),
                  ),
                  // 원형 마커 (카드 내부)
                  Positioned(
                    left: 50,
                    bottom: 16,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: ShapeDecoration(
                        color: Colors.white /* Gray-0 */,
                        shape: OvalBorder(
                          side: BorderSide(
                            width: 2,
                            color: AppColors.primary, /* Primary-Main */
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // Alpaca 연동 전 - 실제 자산 정보 위에 블러 오버레이
      return Stack(
        children: [
          // 실제 자산 정보 (연동 후와 동일한 구조)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 9),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: double.infinity,
                  height: 68,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 352,
                        height: 50,
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              top: 0,
                              child: Container(
                                width: 172,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 172,
                                      child: Text(
                                        '보유자산',
                                        style: AppFonts.bodyLargeSemiBold.copyWith(color: AppColors.gray900),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 172,
                                      child: Text(
                                        '\$ --,---,---',
                                        style: AppFonts.titleMedium.copyWith(color: AppColors.gray600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              left: 303,
                              top: 26,
                              child: Text(
                                '상세보기',
                                textAlign: TextAlign.center,
                              style: AppFonts.captionLargeSemiBold.copyWith(
                                  color: AppColors.gray600, /* Gray-600 */
                                  height: 1.71,
                       ),
              ),
            ),
          ],
        ),
      ),
                    ],
                  ),
                ),
                Container(
                  width: 359,
                  height: 125,
                  decoration: ShapeDecoration(
                    color: Colors.white /* Gray-0 */,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 1,
                        color: AppColors.gray300, /* Gray-300 */
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // 차트 영역 플레이스홀더
                      Positioned(
                        left: 16,
                        top: 16,
                        right: 16,
                        bottom: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              '차트 영역',
                              style: AppFonts.captionLargeRegular.copyWith(color: AppColors.gray300),
                            ),
                          ),
                        ),
                      ),
                      // 수익률 표시 플레이스홀더
                      Positioned(
                        right: 16,
                        top: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: ShapeDecoration(
                            color: AppColors.surfaceVariant,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                          child: Text(
                            '--%',
                            style: AppFonts.captionSmallRegular.copyWith(color: AppColors.gray300),
                          ),
                        ),
                      ),
                      // 기간 표시 플레이스홀더
                      Positioned(
                        left: 16,
                        bottom: 16,
                        child: Text(
                          '--/--',
                          style: AppFonts.captionSmallRegular.copyWith(color: AppColors.gray300),
                        ),
                      ),
                      // 원형 마커 플레이스홀더
                      Positioned(
                        left: 50,
                        bottom: 16,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: ShapeDecoration(
                            color: AppColors.gray300,
                            shape: OvalBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 블러 오버레이와 버튼
          Positioned(
            left: 16,
            top: 0,
            right: 16,
            bottom: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                  ),
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        context.push('/alpaca-auth');
                      },
                      child: Container(
                        width: 103,
                        height: 35,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: ShapeDecoration(
                          color: AppColors.gray900,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 79,
                              child: Text(
                              '계좌 연결하기',
                                textAlign: TextAlign.center,
                                style: AppFonts.captionLargeSemiBold.copyWith(color: AppColors.white),
              ),
            ),
          ],
                        ),
        ),
      ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
    }
  }

  // 해외 종목 순위 섹션
  Widget _buildStockRankingSection() {
    return Container(
      padding: const EdgeInsets.only(top: 20, bottom: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
            child:             Text(
              '해외 종목 순위',
              style: AppFonts.titleMedium.copyWith(color: AppColors.gray900),
            ),
          ),
          // 정렬 버튼들
          Container(
            padding: const EdgeInsets.only(top: 1, left: 16, right: 16, bottom: 9),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSortButton('상승률순', 'gain', _selectedSortBy == 'gain'),
                  const SizedBox(width: 9),
                  _buildSortButton('하락률순', 'loss', _selectedSortBy == 'loss'),
                  const SizedBox(width: 9),
                  _buildSortButton('거래량순', 'volume', _selectedSortBy == 'volume'),
                  const SizedBox(width: 9),
                  _buildSortButton('급등 거래량순', 'surge', _selectedSortBy == 'surge'),
                ],
              ),
            ),
          ),
          // 종목 순위 리스트
          if (_stockRanking.isNotEmpty) ...[
            ..._stockRanking.map((stock) => _buildStockRankingItem(stock)),
          ] else ...[
            // 로딩 중
            Container(
              height: 300,
        decoration: BoxDecoration(
          color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 정렬 버튼 위젯
  Widget _buildSortButton(String text, String sortBy, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSortBy = sortBy;
        });
        _loadStockRanking();
      },
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: ShapeDecoration(
          color: isSelected ? AppColors.primary : AppColors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: 1,
              color: AppColors.gray300, // Gray-300
            ),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: AppFonts.captionLargeRegular.copyWith(
              color: isSelected ? AppColors.white : AppColors.gray600,
            ),
          ),
        ),
      ),
    );
  }

  // 종목 순위 아이템 위젯
  Widget _buildStockRankingItem(StockRankingModel stock) {
    final index = _stockRanking.indexOf(stock);
    final isSelected = _selectedStockIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStockIndex = isSelected ? null : index;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 56,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.background : AppColors.white,
          border: Border(
            top: BorderSide(
              width: 1,
              color: AppColors.borderLight, // Gray-100
            ),
            bottom: BorderSide(
              width: 1,
              color: AppColors.borderLight, // Gray-100
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // 순위
              SizedBox(
                width: 24,
                child: Text(
                  stock.rank.toString(),
                  textAlign: TextAlign.center,
                  style: AppFonts.captionLargeRegular.copyWith(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 10),
              // 종목명
              Expanded(
                flex: 2,
                child: Text(
                  stock.name,
                  style: AppFonts.bodyLarge.copyWith(color: AppColors.gray900),
                ),
              ),
              // 가격
              SizedBox(
                width: 80,
                child: Text(
                  '가격',
                  textAlign: TextAlign.center,
                  style: AppFonts.captionLargeRegular.copyWith(color: AppColors.gray900),
                ),
              ),
              // 변동률
              SizedBox(
                width: 80,
                child: Text(
                  '수익률',
                  textAlign: TextAlign.center,
                  style: AppFonts.captionLargeRegular.copyWith(color: AppColors.profit),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 주식 검색 처리
  void _searchStock(String symbol) {
    if (symbol.isNotEmpty) {
      // 검색 결과 페이지로 이동
      context.push('/stock/${symbol.toUpperCase()}');
    }
  }

  // 해외 주요 지수 섹션
  Widget _buildOverseasIndicesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.only(top: 8, bottom: 9), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child:             Text(
              '해외 주요 지수',
              style: AppFonts.titleMedium.copyWith(color: AppColors.gray900),
            ),
          ),
          const SizedBox(height: 8),
          // API에서 가져온 데이터로 동적 생성
          if (_overseasIndices.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: _buildIndexItem(
                    _overseasIndices[0].name,
                    _formatPrice(_overseasIndices[0].currentPrice),
                    _formatChange(_overseasIndices[0].changeAmount, _overseasIndices[0].changePercentage),
                    _overseasIndices[0].isPositive,
                  ),
                ),
                if (_overseasIndices.length > 1) ...[
                const SizedBox(width: 12),
                Expanded(
                    child: _buildIndexItem(
                      _overseasIndices[1].name,
                      _formatPrice(_overseasIndices[1].currentPrice),
                      _formatChange(_overseasIndices[1].changeAmount, _overseasIndices[1].changePercentage),
                      _overseasIndices[1].isPositive,
                        ),
                      ),
                    ],
              ],
            ),
          ] else ...[
            // 로딩 중 또는 데이터 없음
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 가격 포맷팅
  String _formatPrice(dynamic price) {
    if (price is num) {
      return price.toStringAsFixed(2);
    }
    if (price is String) {
      final parsed = double.tryParse(price);
      if (parsed != null) {
        return parsed.toStringAsFixed(2);
      }
    }
    return '0.00';
  }

  // 변동률 포맷팅
  String _formatChange(dynamic change, dynamic changePercent) {
    final changeNum = change is num ? change : 0.0;
    final percentNum = changePercent is num ? changePercent : 0.0;
    
    final sign = changeNum >= 0 ? '+' : '';
    return '$sign${changeNum.toStringAsFixed(2)} (${percentNum.toStringAsFixed(2)}%)';
  }

  // 지수 이름을 표시용으로 변환
  String _getDisplayName(String name) {
    if (name.contains('나스닥') || name.contains('NASDAQ')) {
      return 'NASDAQ';
    } else if (name.contains('S&P') || name.contains('SPX')) {
      return 'S&P 500';
    }
    return name;
  }

  // 지수 아이템 위젯
  Widget _buildIndexItem(String name, String value, String change, bool isPositive) {
    return Container(
      height: 120, 
      padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 14), 
      decoration: BoxDecoration(
        color: AppColors.background, 
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, 
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/america.png',
                width: 16,
                height: 16,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.flag,
                      size: 10,
                      color: Colors.white,
                    ),
                  );
                },
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _getDisplayName(name),
                                  style: AppFonts.captionLargeRegular.copyWith(color: AppColors.gray900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8), // gap: 0.625rem
          Text(
            value,
            style: AppFonts.titleMedium.copyWith(
              color: AppColors.gray900,
              fontWeight: FontWeight.w700,
              height: 1.20,
            ),
          ),
          const SizedBox(height: 8), 
          Row(
            children: [
              Icon(
                isPositive ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 16,
                color: isPositive ? AppColors.profit : AppColors.loss,
              ),
              Text(
                change,
                style: AppFonts.captionLargeRegular.copyWith(
                  color: isPositive ? AppColors.profit : AppColors.loss, // Chart-Red : Blue
                  height: 1.71,
                ),
              ),
            ],
          ),
          ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0, // AppBar의 기본 좌측 패딩 제거
        title: Container(
          width: double.infinity, 
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
          children: [
              Text(
                '모의투자',
                style: AppFonts.titleLarge.copyWith(color: AppColors.gray900),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                // 알림 기능
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {
                // 설정 기능
              },
            ),
          ],
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 검색바 섹션
            _buildSearchSection(),
            
            // 해외 주요 지수 섹션
            _buildOverseasIndicesSection(),
            
            const SizedBox(height: 20),
            
            // 보유자산 섹션
            _buildAssetSection(),
            
            // 해외 종목 순위 섹션
            _buildStockRankingSection(),
            
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBarWidget(
        currentIndex: _getCurrentIndex(),
        onTap: _onNavItemTap,
      ),
    );
  }

  @override
  void dispose() {
    _tokenExpiredSubscription?.cancel();
    super.dispose();
  }
}
