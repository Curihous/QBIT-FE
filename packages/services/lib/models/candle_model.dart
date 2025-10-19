class CandleData {
  final int timestamp;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  CandleData({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  factory CandleData.fromJson(Map<String, dynamic> json) {
    return CandleData(
      timestamp: json['timestamp'] ?? json['openTime'] ?? 0,
      open: (json['open'] ?? 0.0).toDouble(),
      high: (json['high'] ?? 0.0).toDouble(),
      low: (json['low'] ?? 0.0).toDouble(),
      close: (json['close'] ?? 0.0).toDouble(),
      volume: (json['volume'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'open': open,
      'high': high,
      'low': low,
      'close': close,
      'volume': volume,
    };
  }
}

class CandleResponse {
  final String symbol;
  final String interval;
  final List<CandleData> candles;

  CandleResponse({
    required this.symbol,
    required this.interval,
    required this.candles,
  });

  factory CandleResponse.fromJson(Map<String, dynamic> json) {
    return CandleResponse(
      symbol: json['symbol'] ?? '',
      interval: json['interval'] ?? '1d',
      candles: (json['candles'] as List?)
          ?.map((candle) => CandleData.fromJson(candle as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'interval': interval,
      'candles': candles.map((candle) => candle.toJson()).toList(),
    };
  }
}
