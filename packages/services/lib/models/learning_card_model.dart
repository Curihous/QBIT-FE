class LearningCard {
  final int id;
  final String title;
  final String description;
  final List<String> contents;
  final String category;
  final int level;
  final List<String> keywords;
  final List<String> imageUrls;

  LearningCard({
    required this.id,
    required this.title,
    required this.description,
    required this.contents,
    required this.category,
    required this.level,
    required this.keywords,
    required this.imageUrls,
  });

  factory LearningCard.fromJson(Map<String, dynamic> json) {
    // contents가 문자열 배열이거나 JSON 문자열일 수 있음
    List<String> contentsList = [];
    if (json['contents'] != null) {
      if (json['contents'] is List) {
        contentsList = (json['contents'] as List)
            .map((e) => e.toString())
            .toList();
      } else if (json['contents'] is String) {
        // JSON 문자열인 경우 파싱
        try {
          final parsed = json['contents'] as String;
          // 첫 번째와 마지막 문자 제거하고 파싱
          if (parsed.startsWith('[') && parsed.endsWith(']')) {
            contentsList = [parsed];
          } else {
            contentsList = [parsed];
          }
        } catch (e) {
          contentsList = [json['contents'].toString()];
        }
      }
    }

    // keywords가 문자열 배열이거나 단일 문자열일 수 있음
    List<String> keywordsList = [];
    if (json['keywords'] != null) {
      if (json['keywords'] is List) {
        keywordsList = (json['keywords'] as List)
            .map((e) => e.toString())
            .toList();
      } else if (json['keywords'] is String) {
        keywordsList = [json['keywords'] as String];
      }
    }

    // image_urls 처리
    List<String> imageUrlsList = [];
    if (json['image_urls'] != null) {
      if (json['image_urls'] is List) {
        imageUrlsList = (json['image_urls'] as List)
            .map((e) => e.toString())
            .toList();
      } else if (json['image_urls'] is String) {
        imageUrlsList = [json['image_urls'] as String];
      }
    }

    return LearningCard(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      contents: contentsList,
      category: json['category'] as String,
      level: json['level'] as int,
      keywords: keywordsList,
      imageUrls: imageUrlsList,
    );
  }
}
