import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:stock_app/services/env.dart';
import 'package:stock_app/models/searchapi.dart';

class FinnhubSearch {
  List<SearchApi> searchResults = [];
  final String apiKey = Env.finnhubApiKey;
  String searchUrl =
      'https://finnhub.io/api/v1/search?q=apple&token=${Env.finnhubApiKey}';

  Future<List<SearchApi>> getSearchApiList() async {
    final results = <SearchApi>[];

    try {
      final url = Uri.parse(searchUrl);
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final items = body['result'] as List<dynamic>? ?? [];
        results.addAll(
          items.map((e) => SearchApi.fromJson(e as Map<String, dynamic>)),
        );
      } else {
        debugPrint('api error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('error: $e');
    }

    return results;
  }
}
