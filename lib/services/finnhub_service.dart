import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:stock_app/services/env.dart';
import 'package:stock_app/services/historical_data_service.dart';

class FinnhubService {
  static final _base = 'https://finnhub.io/api/v1';
  static const _timeout = Duration(seconds: 10);

  /// Fetch OHLC historical data between [from] and [to] (inclusive).
  /// Returns a list of HistoricalDataPoint or throws on non-recoverable errors.
  static Future<List<HistoricalDataPoint>> fetchHistorical(
    String symbol,
    DateTime from,
    DateTime to, {
    http.Client? client,
  }) async {
    final key = Env.finnhubApiKey;
    final normalizedSymbol = _normalizeSymbol(symbol);
    final httpClient = client ?? http.Client();

    try {
      // Finnhub uses Unix timestamps
      final fromTimestamp = (from.millisecondsSinceEpoch / 1000).toInt();
      final toTimestamp = (to.millisecondsSinceEpoch / 1000).toInt();

      // Use daily resolution ('D') for candle data
      final url = Uri.parse(
        '$_base/stock/candle'
        '?symbol=${Uri.encodeQueryComponent(normalizedSymbol)}'
        '&resolution=D'
        '&from=$fromTimestamp'
        '&to=$toTimestamp'
        '&token=$key',
      );

      debugPrint('Fetching historical data: ${url.toString()}');

      final resp = await httpClient.get(url).timeout(_timeout);

      if (resp.statusCode == 200) {
        final body = json.decode(resp.body) as Map<String, dynamic>;

        // Check if request was successful
        if (body['s'] == 'no_data' || body['s'] == 'error') {
          debugPrint('Finnhub returned: ${body['s']}');
          return <HistoricalDataPoint>[];
        }

        // Parse candle data
        final timestamps = (body['t'] as List<dynamic>?) ?? [];
        final opens = (body['o'] as List<dynamic>?) ?? [];
        final highs = (body['h'] as List<dynamic>?) ?? [];
        final lows = (body['l'] as List<dynamic>?) ?? [];
        final closes = (body['c'] as List<dynamic>?) ?? [];
        final volumes = (body['v'] as List<dynamic>?) ?? [];

        if (timestamps.isEmpty) return <HistoricalDataPoint>[];

        final points = <HistoricalDataPoint>[];
        for (int i = 0; i < timestamps.length; i++) {
          final timestamp = DateTime.fromMillisecondsSinceEpoch(
            (timestamps[i] as num).toInt() * 1000,
          ).toLocal();
          final open = (opens.length > i ? opens[i] as num : 0.0).toDouble();
          final high = (highs.length > i ? highs[i] as num : open).toDouble();
          final low = (lows.length > i ? lows[i] as num : open).toDouble();
          final close = (closes.length > i ? closes[i] as num : open)
              .toDouble();
          final volume = (volumes.length > i ? volumes[i] as num : 0).toInt();

          points.add(
            HistoricalDataPoint(
              timestamp: timestamp,
              open: open,
              high: high,
              low: low,
              close: close,
              volume: volume,
            ),
          );
        }

        return points;
      } else if (resp.statusCode == 429) {
        debugPrint('Finnhub rate limit hit');
        return <HistoricalDataPoint>[];
      } else {
        debugPrint('Finnhub API error: ${resp.statusCode} - ${resp.body}');
        return <HistoricalDataPoint>[];
      }
    } catch (e) {
      debugPrint('Finnhub request failed: $e');
      return <HistoricalDataPoint>[];
    } finally {
      if (client == null) httpClient.close();
    }
  }

  /// Fetch the latest quote price for a symbol.
  static Future<double?> fetchLatestClose(
    String symbol, {
    http.Client? client,
  }) async {
    final key = Env.finnhubApiKey;
    final normalizedSymbol = _normalizeSymbol(symbol);
    final httpClient = client ?? http.Client();

    try {
      final url = Uri.parse(
        '$_base/quote'
        '?symbol=${Uri.encodeQueryComponent(normalizedSymbol)}'
        '&token=$key',
      );

      debugPrint('Fetching latest quote: ${url.toString()}');

      final resp = await httpClient.get(url).timeout(_timeout);

      if (resp.statusCode == 200) {
        final body = json.decode(resp.body) as Map<String, dynamic>;
        final close = (body['c'] as num?)?.toDouble();
        return close;
      } else if (resp.statusCode == 429) {
        debugPrint('Finnhub rate limit hit');
        return null;
      } else {
        debugPrint('Finnhub quote error: ${resp.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Finnhub quote request failed: $e');
      return null;
    } finally {
      if (client == null) httpClient.close();
    }
  }

  /// Fetch company profile data for a symbol.
  static Future<Map<String, String>> fetchCompanyProfile(
    String symbol, {
    http.Client? client,
  }) async {
    final key = Env.finnhubApiKey;
    final normalizedSymbol = _normalizeSymbol(symbol);
    final httpClient = client ?? http.Client();

    try {
      final url = Uri.parse(
        '$_base/stock/profile2'
        '?symbol=${Uri.encodeQueryComponent(normalizedSymbol)}'
        '&token=$key',
      );

      debugPrint('Fetching company profile: ${url.toString()}');

      final resp = await httpClient.get(url).timeout(_timeout);

      if (resp.statusCode != 200) {
        return const {'name': '', 'logo': ''};
      }

      final body = json.decode(resp.body) as Map<String, dynamic>;
      return {
        'name': (body['name'] as String?) ?? '',
        'logo': (body['logo'] as String?) ?? '',
      };
    } catch (e) {
      debugPrint('Finnhub profile request failed: $e');
      return const {'name': '', 'logo': ''};
    } finally {
      if (client == null) httpClient.close();
    }
  }

  /// Search for symbols matching the query.
  static Future<List<Map<String, String>>> searchTickers(
    String query, {
    http.Client? client,
    int limit = 20,
  }) async {
    final key = Env.finnhubApiKey;
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) return [];

    final httpClient = client ?? http.Client();
    try {
      final url = Uri.parse(
        '$_base/search'
        '?q=${Uri.encodeQueryComponent(normalizedQuery)}'
        '&token=$key',
      );

      debugPrint('Searching tickers: ${url.toString()}');

      for (var attempt = 0; attempt < 3; attempt++) {
        try {
          final resp = await httpClient.get(url).timeout(_timeout);

          if (resp.statusCode == 200) {
            final body = json.decode(resp.body) as Map<String, dynamic>;
            final results = (body['result'] as List<dynamic>?) ?? [];

            return results
                .whereType<Map<String, dynamic>>()
                .take(limit)
                .map(
                  (item) => {
                    'symbol': (item['symbol'] as String?) ?? '',
                    'description': (item['description'] as String?) ?? '',
                  },
                )
                .where((item) => (item['symbol'] ?? '').isNotEmpty)
                .toList();
          }

          if (resp.statusCode == 429 && attempt < 2) {
            await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
            continue;
          }

          debugPrint('Finnhub search failed: ${resp.statusCode}');
          return [];
        } catch (e) {
          debugPrint('Finnhub search error: $e');
          if (attempt == 2) return [];
          await Future.delayed(Duration(milliseconds: 300 * (attempt + 1)));
        }
      }

      return [];
    } finally {
      if (client == null) httpClient.close();
    }
  }

  /// Normalize symbol format for Finnhub API
  /// - Remove special prefixes like ^ (used for indices)
  /// - Convert to uppercase
  static String _normalizeSymbol(String symbol) {
    var s = symbol.trim().toUpperCase();
    // Remove ^ prefix used for indices
    if (s.startsWith('^')) {
      s = s.substring(1);
    }
    return s;
  }
}
