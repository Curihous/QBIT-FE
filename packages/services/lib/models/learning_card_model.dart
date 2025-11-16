import 'dart:convert';

/// 학습 카드 모델
class LearningCard {
  final int id;
  final String title;
  final String description;
  final dynamic contents; // string[] | string
  final String category;
  final int level;
  final dynamic keywords; // string[] | null
  final String createdAt;
  final String updatedAt;

  LearningCard({
    required this.id,
    required this.title,
    required this.description,
    required this.contents,
    required this.category,
    required this.level,
    required this.keywords,
    required this.createdAt,
    required this.updatedAt,
  });

  /// JSON에서 LearningCard 객체 생성
  factory LearningCard.fromJson(Map<String, dynamic> json) {
    // keywords 파싱 (배열 또는 null)
    dynamic keywordsData = json['keywords'];
    if (keywordsData is String) {
      try {
        keywordsData = jsonDecode(keywordsData);
      } catch (e) {
        keywordsData = null;
      }
    }

    // contents 파싱 (배열 또는 문자열)
    dynamic contentsData = json['contents'];
    if (contentsData is String) {
      try {
        contentsData = jsonDecode(contentsData);
      } catch (e) {
        // 파싱 실패 시 문자열 그대로 사용
      }
    }

    return LearningCard(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      contents: contentsData,
      category: json['category'] as String,
      level: json['level'] as int,
      keywords: keywordsData,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  /// keywords를 List<String>으로 변환
  List<String> get keywordsList {
    if (keywords == null) return [];
    if (keywords is List) {
      return (keywords as List).map((e) => e.toString()).toList();
    }
    return [];
  }

  /// contents를 List<String>으로 변환
  List<String> get contentsList {
    if (contents is List) {
      return (contents as List).map((e) => e.toString()).toList();
    }
    if (contents is String) {
      return [contents as String];
    }
    return [];
  }
}

/// 학습 카드 목록 응답 모델
class LearningCardsResponse {
  final bool success;
  final int totalCount;
  final List<LearningCard> cards;

  LearningCardsResponse({
    required this.success,
    required this.totalCount,
    required this.cards,
  });

  factory LearningCardsResponse.fromJson(Map<String, dynamic> json) {
    return LearningCardsResponse(
      success: json['success'] as bool? ?? true,
      totalCount: json['total_count'] as int? ?? 0,
      cards: (json['cards'] as List<dynamic>?)
              ?.map((e) => LearningCard.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// 학습 카드 상세 응답 모델
class LearningCardDetailResponse {
  final bool success;
  final LearningCard card;

  LearningCardDetailResponse({
    required this.success,
    required this.card,
  });

  factory LearningCardDetailResponse.fromJson(Map<String, dynamic> json) {
    return LearningCardDetailResponse(
      success: json['success'] as bool? ?? true,
      card: LearningCard.fromJson(json['card'] as Map<String, dynamic>),
    );
  }
}

