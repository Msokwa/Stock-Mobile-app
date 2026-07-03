import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:stock_app/services/env.dart';
import 'package:stock_app/models/stockapi.dart';

class FinnhubStockService {
  static String get apiKey => Env.finnhubApiKey;
  static String baseUrl(String query) =>
      'https://finnhub.io/api/v1/search?q=${Uri.encodeQueryComponent(query)}&token=${Env.finnhubApiKey}';

  static Future<StockApi?> fetchStocksApi(String query) async {
    try {
      final response = await http.get(Uri.parse(baseUrl(query)));

      if (response.statusCode == 200) {
        return StockApi.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load stocks');
      }
    } catch (e) {
      debugPrint('Error fetching stocks: $e');
      return null;
    }
  }
}
