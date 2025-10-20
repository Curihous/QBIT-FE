// 데모용 포트폴리오 히스토리 데이터 모델
class PortfolioHistoryData {
  final String period;
  final String timeframe;
  final double baseValue;
  final List<int> timestamp;
  final List<double> equity;
  final List<double> profitLoss;
  final List<double> profitLossPct;

  PortfolioHistoryData({
    required this.period,
    required this.timeframe,
    required this.baseValue,
    required this.timestamp,
    required this.equity,
    required this.profitLoss,
    required this.profitLossPct,
  });

  factory PortfolioHistoryData.fromJson(Map<String, dynamic> json) {
    return PortfolioHistoryData(
      period: json['period'] as String,
      timeframe: json['timeframe'] as String,
      baseValue: (json['base_value'] as num).toDouble(),
      timestamp: List<int>.from(json['timestamp']),
      equity: List<double>.from(json['equity'].map((e) => (e as num).toDouble())),
      profitLoss: List<double>.from(json['profit_loss'].map((e) => (e as num).toDouble())),
      profitLossPct: List<double>.from(json['profit_loss_pct'].map((e) => (e as num).toDouble())),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period': period,
      'timeframe': timeframe,
      'base_value': baseValue,
      'timestamp': timestamp,
      'equity': equity,
      'profit_loss': profitLoss,
      'profit_loss_pct': profitLossPct,
    };
  }
}

// UI에서 바로 쓰기 편한 형태의 데이터 모델
class PortfolioChartPoint {
  final String label;
  final double equity;
  final int timestamp;

  PortfolioChartPoint({
    required this.label,
    required this.equity,
    required this.timestamp,
  });

  factory PortfolioChartPoint.fromJson(Map<String, dynamic> json) {
    return PortfolioChartPoint(
      label: json['label'] as String,
      equity: (json['equity'] as num).toDouble(),
      timestamp: json['ts'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'equity': equity,
      'ts': timestamp,
    };
  }
}

// 데모용 목업 데이터
class PortfolioHistoryMockData {
  // 데모용 - Alpaca 스타일 원본 데이터
  static PortfolioHistoryData get alpacaStyleData => PortfolioHistoryData.fromJson({
    "period": "1D",
    "timeframe": "1Hour",
    "base_value": 100120.50,
    "timestamp": [
      1761033600, 1761037200, 1761040800, 1761044400, 1761048000,
      1761051600, 1761055200, 1761058800, 1761062400
    ],
    "equity": [
      100120.50, 100180.20, 100140.10, 100160.30, 100155.00,
      100130.75, 100110.40, 100020.15, 100050.80
    ],
    "profit_loss": [
      0.00, 59.70, 19.60, 39.80, 34.50, 10.25, -10.10, -100.35, -69.70
    ],
    "profit_loss_pct": [
      0.000000, 0.000596, 0.000196, 0.000398, 0.000345,
      0.000102, -0.000101, -0.001002, -0.000696
    ]
  });

  // 데모용 - UI에서 바로 쓰기 편한 형태 (현실적인 변동성)
  static List<PortfolioChartPoint> get chartPoints => [
    PortfolioChartPoint(label: "6:30", equity: 100120.50, timestamp: 1761033600),
    PortfolioChartPoint(label: "7:00", equity: 100145.20, timestamp: 1761037200),
    PortfolioChartPoint(label: "7:30", equity: 100118.80, timestamp: 1761040800),
    PortfolioChartPoint(label: "8:00", equity: 100165.30, timestamp: 1761044400),
    PortfolioChartPoint(label: "8:30", equity: 100132.10, timestamp: 1761048000),
    PortfolioChartPoint(label: "9:00", equity: 100188.70, timestamp: 1761051600),
    PortfolioChartPoint(label: "9:30", equity: 100210.20, timestamp: 1761055200),
    PortfolioChartPoint(label: "10:00", equity: 100185.50, timestamp: 1761058800),
    PortfolioChartPoint(label: "10:30", equity: 100172.80, timestamp: 1761062400),
    PortfolioChartPoint(label: "11:00", equity: 100155.10, timestamp: 1761066000),
    PortfolioChartPoint(label: "11:30", equity: 100142.40, timestamp: 1761069600),
    PortfolioChartPoint(label: "12:00", equity: 100128.20, timestamp: 1761073200),
    PortfolioChartPoint(label: "12:30", equity: 100115.10, timestamp: 1761076800),
  ];

  // 현재 포트폴리오 값 (마지막 equity 값)
  static double get currentPortfolioValue => chartPoints.last.equity;

  // 현재 수익률 (첫 번째 값 대비 마지막 값의 변화율)
  static double get currentReturnPercentage {
    final firstValue = chartPoints.first.equity;
    final lastValue = chartPoints.last.equity;
    return ((lastValue - firstValue) / firstValue) * 100;
  }
}
