class CardNewsModel {
  final String id;
  final String title;
  final String imagePath;
  final String category;
  final List<String> tags;
  final int order;
  final bool isTitleCard;
  final Map<String, dynamic>? metadata;

  const CardNewsModel({
    required this.id,
    required this.title,
    required this.imagePath,
    required this.category,
    required this.tags,
    required this.order,
    this.isTitleCard = false,
    this.metadata,
  });

  factory CardNewsModel.fromJson(Map<String, dynamic> json) {
    return CardNewsModel(
      id: json['id'] as String,
      title: json['title'] as String,
      imagePath: json['imagePath'] as String,
      category: json['category'] as String,
      tags: List<String>.from(json['tags'] as List),
      order: json['order'] as int,
      isTitleCard: json['isTitleCard'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'imagePath': imagePath,
      'category': category,
      'tags': tags,
      'order': order,
      'isTitleCard': isTitleCard,
      'metadata': metadata,
    };
  }
}

class CardNewsSet {
  final String setId;
  final String title;
  final String description;
  final List<CardNewsModel> cards;
  final String category;
  final List<String> applicableTags;

  const CardNewsSet({
    required this.setId,
    required this.title,
    required this.description,
    required this.cards,
    required this.category,
    required this.applicableTags,
  });

  factory CardNewsSet.fromJson(Map<String, dynamic> json) {
    return CardNewsSet(
      setId: json['setId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      cards: (json['cards'] as List)
          .map((card) => CardNewsModel.fromJson(card as Map<String, dynamic>))
          .toList(),
      category: json['category'] as String,
      applicableTags: List<String>.from(json['applicableTags'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'setId': setId,
      'title': title,
      'description': description,
      'cards': cards.map((card) => card.toJson()).toList(),
      'category': category,
      'applicableTags': applicableTags,
    };
  }
}

