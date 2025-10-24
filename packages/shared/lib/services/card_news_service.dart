import '../models/card_news_model.dart';

class CardNewsService {
  static final CardNewsService _instance = CardNewsService._internal();
  factory CardNewsService() => _instance;
  CardNewsService._internal();

  // 카드뉴스 세트들을 저장하는 맵
  final Map<String, CardNewsSet> _cardNewsSets = {};

  // AI 리포트 분석 결과에서 추출된 태그들
  List<String> _extractedTags = [];

  /// 카드뉴스 세트 등록
  void registerCardNewsSet(CardNewsSet cardNewsSet) {
    _cardNewsSets[cardNewsSet.setId] = cardNewsSet;
  }

  /// AI 리포트에서 추출된 태그 설정
  void setExtractedTags(List<String> tags) {
    _extractedTags = tags;
  }

  /// 태그 기반으로 적절한 카드뉴스 세트 찾기
  CardNewsSet? findMatchingCardNewsSet() {
    if (_extractedTags.isEmpty) {
      return null;
    }

    // 태그 매칭 점수 계산
    String? bestMatchSetId;
    int bestMatchScore = 0;

    for (final setId in _cardNewsSets.keys) {
      final cardNewsSet = _cardNewsSets[setId]!;
      final matchScore = _calculateMatchScore(
        _extractedTags,
        cardNewsSet.applicableTags,
      );

      if (matchScore > bestMatchScore) {
        bestMatchScore = matchScore;
        bestMatchSetId = setId;
      }
    }

    return bestMatchSetId != null ? _cardNewsSets[bestMatchSetId] : null;
  }

  /// 태그 매칭 점수 계산
  int _calculateMatchScore(List<String> extractedTags, List<String> applicableTags) {
    int score = 0;
    for (final tag in extractedTags) {
      if (applicableTags.contains(tag)) {
        score++;
      }
    }
    return score;
  }

  /// 특정 카테고리의 카드뉴스 세트 가져오기
  CardNewsSet? getCardNewsSetByCategory(String category) {
    for (final cardNewsSet in _cardNewsSets.values) {
      if (cardNewsSet.category == category) {
        return cardNewsSet;
      }
    }
    return null;
  }

  /// 모든 카드뉴스 세트 가져오기
  List<CardNewsSet> getAllCardNewsSets() {
    return _cardNewsSets.values.toList();
  }

  /// 기본 카드뉴스 세트 초기화 (목업 데이터)
  void initializeDefaultCardNewsSets() {
    // 리스크 관리 카드뉴스 세트
    final riskManagementSet = CardNewsSet(
      setId: 'risk_management',
      title: '손절매와 익절 기준 설정',
      description: '투자에서 손실을 최소화하고 수익을 극대화하는 방법을 알아보세요.',
      category: 'risk_management',
      applicableTags: [
        '손절매',
        '익절',
        '리스크관리',
        '손실',
        '수익',
        '기준설정',
        '매도타이밍',
        '목표가',
      ],
      cards: [
        CardNewsModel(
          id: 'risk_title',
          title: '손절매와 익절 기준 설정',
          imagePath: 'assets/cards/risk/title.png',
          category: 'risk_management',
          tags: ['리스크관리'],
          order: 0,
          isTitleCard: true,
        ),
        CardNewsModel(
          id: 'risk_1',
          title: '손절매란?',
          imagePath: 'assets/cards/risk/1.png',
          category: 'risk_management',
          tags: ['손절매', '손실'],
          order: 1,
        ),
        CardNewsModel(
          id: 'risk_2',
          title: '익절이란?',
          imagePath: 'assets/cards/risk/2.png',
          category: 'risk_management',
          tags: ['익절', '수익'],
          order: 2,
        ),
        CardNewsModel(
          id: 'risk_3',
          title: '기준 설정 방법',
          imagePath: 'assets/cards/risk/3.png',
          category: 'risk_management',
          tags: ['기준설정', '매도타이밍'],
          order: 3,
        ),
        CardNewsModel(
          id: 'risk_4',
          title: '실전 적용 팁',
          imagePath: 'assets/cards/risk/4.png',
          category: 'risk_management',
          tags: ['목표가', '실전'],
          order: 4,
        ),
      ],
    );

    // 투자 심리 카드뉴스 세트
    final investmentPsychologySet = CardNewsSet(
      setId: 'investment_psychology',
      title: '공포에 사라는 말, 진짜일까?',
      description: '투자에서 감정을 통제하고 합리적인 판단을 내리는 방법을 배워보세요.',
      category: 'investment_psychology',
      applicableTags: [
        '투자심리',
        '공포',
        '탐욕',
        '감정통제',
        '합리적판단',
        '심리적요인',
        '투자심리학',
      ],
      cards: [
        CardNewsModel(
          id: 'psychology_title',
          title: '공포에 사라는 말, 진짜일까?',
          imagePath: 'assets/cards/psychology/title.png',
          category: 'investment_psychology',
          tags: ['투자심리'],
          order: 0,
          isTitleCard: true,
        ),
        CardNewsModel(
          id: 'psychology_1',
          title: '투자에서의 공포',
          imagePath: 'assets/cards/psychology/1.png',
          category: 'investment_psychology',
          tags: ['공포', '심리적요인'],
          order: 1,
        ),
        CardNewsModel(
          id: 'psychology_2',
          title: '탐욕의 함정',
          imagePath: 'assets/cards/psychology/2.png',
          category: 'investment_psychology',
          tags: ['탐욕', '투자심리학'],
          order: 2,
        ),
        CardNewsModel(
          id: 'psychology_3',
          title: '감정 통제 방법',
          imagePath: 'assets/cards/psychology/3.png',
          category: 'investment_psychology',
          tags: ['감정통제', '합리적판단'],
          order: 3,
        ),
        CardNewsModel(
          id: 'psychology_4',
          title: '성공적인 투자자 되기',
          imagePath: 'assets/cards/psychology/4.png',
          category: 'investment_psychology',
          tags: ['성공', '투자심리'],
          order: 4,
        ),
      ],
    );

    // 기술적 분석 카드뉴스 세트
    final technicalAnalysisSet = CardNewsSet(
      setId: 'technical_analysis',
      title: '차트 분석의 기본',
      description: '주가 차트를 읽고 기술적 지표를 활용하는 방법을 배워보세요.',
      category: 'technical_analysis',
      applicableTags: [
        '기술적분석',
        '차트분석',
        'RSI',
        '이동평균',
        '지지선',
        '저항선',
        '매매신호',
        '기술지표',
      ],
      cards: [
        CardNewsModel(
          id: 'technical_title',
          title: '차트 분석의 기본',
          imagePath: 'assets/cards/technical/title.png',
          category: 'technical_analysis',
          tags: ['기술적분석'],
          order: 0,
          isTitleCard: true,
        ),
        CardNewsModel(
          id: 'technical_1',
          title: '차트의 기본 구조',
          imagePath: 'assets/cards/technical/1.png',
          category: 'technical_analysis',
          tags: ['차트분석', '기본구조'],
          order: 1,
        ),
        CardNewsModel(
          id: 'technical_2',
          title: 'RSI 지표 활용',
          imagePath: 'assets/cards/technical/2.png',
          category: 'technical_analysis',
          tags: ['RSI', '기술지표'],
          order: 2,
        ),
        CardNewsModel(
          id: 'technical_3',
          title: '지지선과 저항선',
          imagePath: 'assets/cards/technical/3.png',
          category: 'technical_analysis',
          tags: ['지지선', '저항선'],
          order: 3,
        ),
        CardNewsModel(
          id: 'technical_4',
          title: '매매 신호 포착',
          imagePath: 'assets/cards/technical/4.png',
          category: 'technical_analysis',
          tags: ['매매신호', '실전활용'],
          order: 4,
        ),
      ],
    );

    // 기본 투자 전략 카드뉴스 세트
    final basicStrategySet = CardNewsSet(
      setId: 'basic_strategy',
      title: '초보자를 위한 투자 전략',
      description: '투자 초보자가 알아야 할 기본적인 투자 전략과 원칙을 배워보세요.',
      category: 'basic_strategy',
      applicableTags: [
        '초보투자',
        '투자전략',
        '분산투자',
        '장기투자',
        '기본원칙',
        '투자기초',
        '포트폴리오',
      ],
      cards: [
        CardNewsModel(
          id: 'strategy_title',
          title: '초보자를 위한 투자 전략',
          imagePath: 'assets/cards/strategy/title.png',
          category: 'basic_strategy',
          tags: ['투자전략'],
          order: 0,
          isTitleCard: true,
        ),
        CardNewsModel(
          id: 'strategy_1',
          title: '투자의 기본 원칙',
          imagePath: 'assets/cards/strategy/1.png',
          category: 'basic_strategy',
          tags: ['기본원칙', '투자기초'],
          order: 1,
        ),
        CardNewsModel(
          id: 'strategy_2',
          title: '분산투자의 중요성',
          imagePath: 'assets/cards/strategy/2.png',
          category: 'basic_strategy',
          tags: ['분산투자', '포트폴리오'],
          order: 2,
        ),
        CardNewsModel(
          id: 'strategy_3',
          title: '장기투자의 장점',
          imagePath: 'assets/cards/strategy/3.png',
          category: 'basic_strategy',
          tags: ['장기투자', '투자전략'],
          order: 3,
        ),
        CardNewsModel(
          id: 'strategy_4',
          title: '성공적인 투자자 되기',
          imagePath: 'assets/cards/strategy/4.png',
          category: 'basic_strategy',
          tags: ['성공', '초보투자'],
          order: 4,
        ),
      ],
    );

    // 시장 분석 카드뉴스 세트
    final marketAnalysisSet = CardNewsSet(
      setId: 'market_analysis',
      title: '시장 분석과 경제 지표',
      description: '경제 지표와 시장 동향을 분석하여 투자 결정에 활용하는 방법을 배워보세요.',
      category: 'market_analysis',
      applicableTags: [
        '시장분석',
        '경제지표',
        '시장동향',
        '경제분석',
        '거시경제',
        '시장환경',
        '경제뉴스',
      ],
      cards: [
        CardNewsModel(
          id: 'market_title',
          title: '시장 분석과 경제 지표',
          imagePath: 'assets/cards/market/title.png',
          category: 'market_analysis',
          tags: ['시장분석'],
          order: 0,
          isTitleCard: true,
        ),
        CardNewsModel(
          id: 'market_1',
          title: '주요 경제 지표',
          imagePath: 'assets/cards/market/1.png',
          category: 'market_analysis',
          tags: ['경제지표', '거시경제'],
          order: 1,
        ),
        CardNewsModel(
          id: 'market_2',
          title: '시장 동향 파악',
          imagePath: 'assets/cards/market/2.png',
          category: 'market_analysis',
          tags: ['시장동향', '시장환경'],
          order: 2,
        ),
        CardNewsModel(
          id: 'market_3',
          title: '경제 뉴스 해석',
          imagePath: 'assets/cards/market/3.png',
          category: 'market_analysis',
          tags: ['경제뉴스', '경제분석'],
          order: 3,
        ),
        CardNewsModel(
          id: 'market_4',
          title: '투자에 활용하기',
          imagePath: 'assets/cards/market/4.png',
          category: 'market_analysis',
          tags: ['투자활용', '실전적용'],
          order: 4,
        ),
      ],
    );

    // 카드뉴스 세트들 등록
    registerCardNewsSet(riskManagementSet);
    registerCardNewsSet(investmentPsychologySet);
    registerCardNewsSet(technicalAnalysisSet);
    registerCardNewsSet(basicStrategySet);
    registerCardNewsSet(marketAnalysisSet);
  }
}

