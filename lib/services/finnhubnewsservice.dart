import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:stock_app/services/env.dart';
import '../models/newsapi.dart';

class FinnhubNewsService {
  final String _apiKey = Env.finnhubApiKey;

  Future<List<NewsApi>> fetchNews(String symbol) async {
    final now = DateTime.now();
    final from = now.month == 1
        ? DateTime(now.year - 1, 12, now.day)
        : DateTime(now.year, now.month - 1, now.day);
    final to = now;

    final uri = Uri.parse(
      'https://finnhub.io/api/v1/company-news'
      '?symbol=${Uri.encodeQueryComponent(symbol)}'
      '&from=${from.toIso8601String().substring(0, 10)}'
      '&to=${to.toIso8601String().substring(0, 10)}'
      '&token=$_apiKey',
    );

    try {
      debugPrint('Fetching news for $symbol from: ${uri.toString()}');

      final response = await http
          .get(uri)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception('News request timed out'),
          );

      debugPrint('News response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        debugPrint(
          'Failed to fetch news: ${response.statusCode} - ${response.body}',
        );
        return [];
      }

      final decoded = json.decode(response.body);
      if (decoded is! List) {
        debugPrint('Invalid news response format: $decoded');
        return [];
      }

      final newsList = decoded
          .map((item) => NewsApi.fromJson(item as Map<String, dynamic>))
          .toList();

      debugPrint(
        'Successfully fetched ${newsList.length} news articles for $symbol',
      );
      return newsList;
    } catch (e) {
      debugPrint('Error fetching news: $e');
      return [];
    }
  }

  /// Fetch news for multiple symbols
  Future<List<NewsApi>> fetchNewsForMultiple(List<String> symbols) async {
    final allNews = <NewsApi>[];
    for (final symbol in symbols) {
      final news = await fetchNews(symbol);
      allNews.addAll(news);
    }

    // Sort by date (newest first)
    allNews.sort((a, b) => b.datetime.compareTo(a.datetime));
    return allNews;
  }
}
