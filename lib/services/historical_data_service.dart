import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

class HistoricalDataPoint {
  final DateTime timestamp;
  final double close;
  final double open;
  final double high;
  final double low;
  final int volume;

  HistoricalDataPoint({
    required this.timestamp,
    required this.close,
    required this.open,
    required this.high,
    required this.low,
    required this.volume,
  });
}

class HistoricalDataService {
  static final Random _random = Random();

  /// Generate 1 year of mock daily historical data
  static Future<List<HistoricalDataPoint>> fetchOneYearData(
    String symbol,
  ) async {
    return _generateMockData(symbol, const Duration(days: 365));
  }

  /// Generate data for a specific range
  static Future<List<HistoricalDataPoint>> fetchDataForRange(
    String symbol,
    Duration duration,
  ) async {
    return _generateMockData(symbol, duration);
  }

  /// Generate realistic mock stock data
  static Future<List<HistoricalDataPoint>> _generateMockData(
    String symbol,
    Duration duration,
  ) async {
    debugPrint('Generating mock data for $symbol');

    final now = DateTime.now();
    final startDate = now.subtract(duration);
    final dataPoints = <HistoricalDataPoint>[];

    // Base price for the stock (varies by symbol for variety)
    double basePrice = _getBasePriceForSymbol(symbol);
    double currentPrice = basePrice;

    // Generate daily data points
    var current = startDate;
    while (current.isBefore(now)) {
      // Skip weekends
      if (current.weekday != DateTime.saturday &&
          current.weekday != DateTime.sunday) {
        // Generate realistic price movement (±2% daily volatility)
        final dailyChange = ((_random.nextDouble() - 0.5) * 0.04);
        final changeAmount = currentPrice * dailyChange;
        final newPrice = (currentPrice + changeAmount).clamp(
          basePrice * 0.5,
          basePrice * 2,
        );

        final open = currentPrice;
        final close = newPrice;
        final high = max(open, close) * (1 + _random.nextDouble() * 0.02);
        final low = min(open, close) * (1 - _random.nextDouble() * 0.02);
        final volume = 1000000 + _random.nextInt(5000000);

        dataPoints.add(
          HistoricalDataPoint(
            timestamp: current,
            close: double.parse(close.toStringAsFixed(2)),
            open: double.parse(open.toStringAsFixed(2)),
            high: double.parse(high.toStringAsFixed(2)),
            low: double.parse(low.toStringAsFixed(2)),
            volume: volume,
          ),
        );

        currentPrice = newPrice;
      }

      current = current.add(const Duration(days: 1));
    }

    debugPrint('Generated ${dataPoints.length} mock data points for $symbol');
    return dataPoints;
  }

  /// Get a realistic base price for a stock symbol
  static double _getBasePriceForSymbol(String symbol) {
    final prices = <String, double>{
      'AAPL': 150.0,
      'GOOGL': 140.0,
      'MSFT': 380.0,
      'AMZN': 170.0,
      'TSLA': 300.0,
      'META': 310.0,
      'NVDA': 900.0,
      'AMD': 170.0,
      'NFLX': 450.0,
      'JPM': 195.0,
      'BAC': 33.0,
      'GS': 408.0,
      'WFC': 50.0,
      'C': 53.0,
      'PG': 165.0,
      'KO': 65.0,
      'JNJ': 155.0,
      'UNH': 500.0,
      'CVX': 165.0,
      'XOM': 110.0,
    };

    return prices[symbol.toUpperCase()] ?? 150.0;
  }
}
