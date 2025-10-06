import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final ApiService _apiService = ApiService();
  
  String? _accessToken;
  String? _refreshToken;
  String? _userId;
  Map<String, dynamic>? _userInfo;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStoredData();
  }

  Future<void> _loadStoredData() async {
    final accessToken = await _storage.read(key: 'access_token');
    final refreshToken = await _storage.read(key: 'refresh_token');
    final userId = await _storage.read(key: 'user_id');
    
    setState(() {
      _accessToken = accessToken;
      _refreshToken = refreshToken;
      _userId = userId;
    });
  }

  Future<void> _testUsersMe() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userInfo = await _apiService.getCurrentUser();
      setState(() {
        _userInfo = userInfo;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('users/me 성공!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('users/me 실패: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearAllData() async {
    await _storage.deleteAll();
    await _loadStoredData();
    setState(() {
      _userInfo = null;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('모든 데이터 삭제됨')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('디버그 화면'),
        backgroundColor: const Color(0xFF00C9A7),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 저장된 토큰 정보
            _buildSection(
              '저장된 토큰 정보',
              [
                _buildInfoRow('Access Token', _accessToken ?? '없음'),
                _buildInfoRow('Refresh Token', _refreshToken ?? '없음'),
                _buildInfoRow('User ID', _userId ?? '없음'),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // 버튼들
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testUsersMe,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C9A7),
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('users/me 테스트'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _clearAllData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('데이터 삭제'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // users/me 결과
            if (_userInfo != null) ...[
              _buildSection(
                'users/me 결과',
                _userInfo!.entries.map((entry) => 
                  _buildInfoRow(entry.key, entry.value.toString())
                ).toList(),
              ),
            ],
            
            const SizedBox(height: 20),
            
            // 네비게이션 버튼
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('로그인 화면'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('홈 화면'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF00C9A7),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
