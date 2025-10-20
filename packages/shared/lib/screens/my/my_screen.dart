import 'package:flutter/material.dart';
import 'package:qbit_shared/theme/app_colors.dart';
import 'package:qbit_shared/widgets/common/header_basic.dart';
import 'package:qbit_services/api/stock_api_service.dart';
import 'package:qbit_services/storage/token_service.dart';
import 'package:go_router/go_router.dart';

class MyScreen extends StatefulWidget {
  const MyScreen({super.key});

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  bool _isAlpacaConnected = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAlpacaConnectionStatus();
  }

  // 알파카 연결 상태 확인
  Future<void> _checkAlpacaConnectionStatus() async {
    try {
      // 로그인 상태 확인
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

  // 알파카 연결 화면으로 이동
  void _goToAlpacaAuth() {
    context.push('/alpaca-auth');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HeaderBasic(
        title: '마이페이지',
        onAlarmPressed: null,
        onSettingPressed: null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '계정 설정',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 20),
            
            // 알파카 연결 상태 카드
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.account_balance,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '알파카 계정',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray900,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _isAlpacaConnected 
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _isAlpacaConnected ? '연결됨' : '연결 안됨',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _isAlpacaConnected 
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isAlpacaConnected 
                          ? '알파카 계정이 연결되어 있습니다.'
                          : '알파카 계정이 연결되어 있지 않습니다.',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.gray600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isAlpacaConnected ? null : _goToAlpacaAuth,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isAlpacaConnected 
                              ? AppColors.gray300 
                              : AppColors.primary,
                          foregroundColor: _isAlpacaConnected 
                              ? AppColors.gray600 
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          _isAlpacaConnected ? '이미 연결됨' : '알파카 계정 연결',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
}