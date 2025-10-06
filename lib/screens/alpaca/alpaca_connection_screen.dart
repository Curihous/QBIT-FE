import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/alpaca_service.dart';

class AlpacaConnectionScreen extends StatefulWidget {
  const AlpacaConnectionScreen({super.key});

  @override
  State<AlpacaConnectionScreen> createState() => _AlpacaConnectionScreenState();
}

class _AlpacaConnectionScreenState extends State<AlpacaConnectionScreen> {
  final AlpacaService _alpacaService = AlpacaService();
  bool _isConnected = false;
  bool _isLoading = true;
  Map<String, dynamic>? _connectionStatus;

  @override
  void initState() {
    super.initState();
    _checkConnectionStatus();
  }

  Future<void> _checkConnectionStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final isConnected = await _alpacaService.isConnected();
      final status = await _alpacaService.getConnectionStatus();
      
      setState(() {
        _isConnected = isConnected;
        _connectionStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _connectAlpaca() async {
    try {
      // TODO: 카카오 로그인 토큰 확인
      // final hasKakaoToken = await KakaoAuthService.isTokenValid();
      // if (!hasKakaoToken) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('먼저 카카오 로그인을 해주세요')),
      //   );
      //   return;
      // }
      
      final success = await _alpacaService.startOAuth();
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alpaca 연결을 시작합니다')),
        );
        // 연결 상태 다시 확인
        await _checkConnectionStatus();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Alpaca 연결 실패: $e')),
      );
    }
  }

  Future<void> _disconnectAlpaca() async {
    try {
      final success = await _alpacaService.disconnect();
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alpaca 연결이 해제되었습니다')),
        );
        await _checkConnectionStatus();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Alpaca 연결 해제 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Alpaca 연결',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.go('/home'),
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Alpaca 계정 연결',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isConnected ? Icons.check_circle : Icons.error,
                                color: _isConnected ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isConnected ? '연결됨' : '연결 안됨',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Alpaca는 미국 주식 거래 API를 제공하는 플랫폼입니다.\n모의투자와 실제 투자 모두 지원합니다.',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_connectionStatus != null) ...[
                    const Text(
                      '연결 상태',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('상태: ${_connectionStatus!['status'] ?? 'N/A'}'),
                            Text('계정 ID: ${_connectionStatus!['accountId'] ?? 'N/A'}'),
                            Text('연결 시간: ${_connectionStatus!['connectedAt'] ?? 'N/A'}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isConnected) ...[
                            ElevatedButton(
                              onPressed: _disconnectAlpaca,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 15,
                                ),
                              ),
                              child: const Text('연결 해제'),
                            ),
                          ] else ...[
                            ElevatedButton(
                              onPressed: _connectAlpaca,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 15,
                                ),
                              ),
                              child: const Text('Alpaca 연결'),
                            ),
                          ],
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: _checkConnectionStatus,
                            child: const Text('연결 상태 새로고침'),
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
