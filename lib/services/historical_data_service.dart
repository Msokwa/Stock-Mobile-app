import 'package:stock_app/services/finnhub_service.dart';

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
  /// Generate 1 year of mock daily historical data
  static Future<List<HistoricalDataPoint>> fetchOneYearData(
    String symbol,
  ) async {
    final now = DateTime.now();
    final from = now.subtract(const Duration(days: 365));
    return await FinnhubService.fetchHistorical(symbol, from, now);
  }

  /// Generate data for a specific range
  static Future<List<HistoricalDataPoint>> fetchDataForRange(
    String symbol,
    Duration duration,
  ) async {
    final now = DateTime.now();
    final from = now.subtract(duration);
    return await FinnhubService.fetchHistorical(symbol, from, now);
  }
}
