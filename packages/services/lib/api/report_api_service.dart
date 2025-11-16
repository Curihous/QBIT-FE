import 'package:dio/dio.dart';
import 'package:qbit_services/models/trade_report_model.dart';

class ReportApiService {
  // AI 리포트 전용 클라이언트 (별도 엔드포인트 사용)
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://ai.qbit.o-r.kr',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );

  /// 매매 리포트 조회
  static Future<TradeReport?> getTradeReport(int tradeCycleId) async {
    try {
      final response = await _dio.get('/reports/$tradeCycleId');
      if (response.statusCode == 200 && response.data != null) {
        return TradeReport.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (_) {
      // 호출 실패 시 null 반환 (상위에서 에러 메시지 처리)
    }
    return null;
  }
}

