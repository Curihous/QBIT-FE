import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:qbit_services/models/learning_card_model.dart';

class LearningCardApiService {
  // AI 서버 전용 클라이언트
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://ai.qbit.o-r.kr',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );
  static final Logger logger = Logger();

  /// 학습 카드 목록 조회
  /// [category] 카테고리 필터 (선택)
  /// [level] 레벨 필터 (선택)
  /// [limit] 최대 개수 (선택)
  static Future<List<LearningCard>?> getLearningCards({
    String? category,
    int? level,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      if (level != null) {
        queryParams['level'] = level;
      }
      if (limit != null) {
        queryParams['limit'] = limit;
      }

      logger.i('학습 카드 조회 시작: category=$category, level=$level, limit=$limit');
      final response = await _dio.get('/learning-cards', queryParameters: queryParams);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final cardsData = data['cards'];
          if (cardsData is List) {
            final cards = (cardsData as List)
                .map((json) => LearningCard.fromJson(json as Map<String, dynamic>))
                .toList();
            logger.i('학습 카드 조회 성공: ${cards.length}개');
            return cards;
          } else {
            logger.e('cards 필드가 List가 아닙니다: ${cardsData.runtimeType}');
            return null;
          }
        } else if (data is List) {
          // 하위 호환성: 직접 List로 오는 경우
          final cards = (data as List)
              .map((json) => LearningCard.fromJson(json as Map<String, dynamic>))
              .toList();
          logger.i('학습 카드 조회 성공: ${cards.length}개');
          return cards;
        } else {
          logger.e('응답 데이터 형식이 예상과 다릅니다: ${data.runtimeType}');
          return null;
        }
      } else {
        logger.e('학습 카드 조회 실패: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      logger.e('학습 카드 조회 에러: $error');
      if (error is DioException) {
        logger.e('Dio 에러 상세: 상태코드 ${error.response?.statusCode}');
        logger.e('Dio 에러 데이터: ${error.response?.data}');
      }
      return null;
    }
  }
}
