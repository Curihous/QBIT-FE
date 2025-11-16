import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../models/learning_card_model.dart';

/// 학습 카드 관련 API 서비스
class LearningCardApiService {
  static const String baseUrl = 'https://ai.qbit.o-r.kr';
  static const Duration timeout = Duration(seconds: 30);
  
  static late Dio _dio;
  static bool _initialized = false;
  static final Logger logger = Logger();

  static void _initialize() {
    if (_initialized) return;
    
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: timeout,
      receiveTimeout: timeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    _initialized = true;
  }

  /// 학습 카드 목록 조회
  /// 
  /// [category] 카테고리 필터 (예: "투자기초", "자산분석", "시스템")
  /// [level] 레벨 필터 (1-5)
  /// [limit] 조회할 최대 개수
  static Future<LearningCardsResponse?> getLearningCards({
    String? category,
    int? level,
    int? limit,
  }) async {
    try {
      _initialize();
      logger.i('학습 카드 목록 조회 시작: category=$category, level=$level, limit=$limit');

      final queryParams = <String, dynamic>{};
      if (category != null) queryParams['category'] = category;
      if (level != null) queryParams['level'] = level;
      if (limit != null) queryParams['limit'] = limit;

      final response = await _dio.get(
        '/learning-cards',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200) {
        logger.i('학습 카드 목록 조회 성공');
        return LearningCardsResponse.fromJson(response.data as Map<String, dynamic>);
      } else {
        logger.e('학습 카드 목록 조회 실패: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      logger.e('학습 카드 목록 조회 에러: $error');
      if (error is DioException) {
        logger.e('Dio 에러 상세: 상태코드 ${error.response?.statusCode}');
        logger.e('응답 데이터: ${error.response?.data}');
      }
      return null;
    }
  }

  /// 학습 카드 상세 조회
  /// 
  /// [cardId] 카드 ID
  static Future<LearningCardDetailResponse?> getLearningCard(int cardId) async {
    try {
      _initialize();
      logger.i('학습 카드 상세 조회 시작: cardId=$cardId');

      final response = await _dio.get('/learning-cards/$cardId');

      if (response.statusCode == 200) {
        logger.i('학습 카드 상세 조회 성공');
        return LearningCardDetailResponse.fromJson(response.data as Map<String, dynamic>);
      } else {
        logger.e('학습 카드 상세 조회 실패: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      logger.e('학습 카드 상세 조회 에러: $error');
      if (error is DioException) {
        logger.e('Dio 에러 상세: 상태코드 ${error.response?.statusCode}');
        logger.e('응답 데이터: ${error.response?.data}');
      }
      return null;
    }
  }
}

