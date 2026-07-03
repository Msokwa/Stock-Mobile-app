import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:stock_app/services/env.dart';
import 'package:stock_app/models/stockdetailsapi.dart';

class FinnhubStockDetailsService {
  static final String api = Env.finnhubApiKey;
  static String baseUrl(String symbol) =>
      'https://finnhub.io/api/v1/quote?symbol=$symbol&token=${Env.finnhubApiKey}';

  static Future<StockDetailsApi> fetchStockDetails(String symbol) async {
    try {
      final response = await http.get(Uri.parse(baseUrl(symbol)));
      if (response.statusCode == 200) {
        return StockDetailsApi.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load stock details');
      }
    } catch (e) {
      debugPrint('Error fetching stock details: $e');
      throw Exception('Failed to load stock details');
    }
  }
}
