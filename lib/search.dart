import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:stock_app/services/env.dart';
import 'package:stock_app/stockdetails.dart';

class Search extends SearchDelegate<String?> {
  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: const Color(0xff091625),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<List<Map<String, String>>> fetchSearch(String query) async {
    final String apiKey = Env.finnhubApiKey;
    final String searchUrl =
        'https://finnhub.io/api/v1/search?q=${Uri.encodeQueryComponent(query)}&token=$apiKey';

    final uri = Uri.parse(searchUrl);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body) as Map<String, dynamic>;
      final data = jsonBody['result'] as List<dynamic>? ?? [];
      return data
          .map(
            (item) => {
              'symbol': item['symbol'] as String? ?? '',
              'description': item['description'] as String? ?? '',
            },
          )
          .toList();
    } else {
      throw Exception('Failed to load search results');
    }
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          query = '';
        },
        icon: Icon(Icons.close),
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back_ios),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Type a stock symbol'));
    }

    return FutureBuilder<List<Map<String, String>>>(
      future: fetchSearch(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final results = snapshot.data ?? [];
        if (results.isEmpty) {
          return const Center(child: Text('No results found'));
        }
        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final result = results[index];
            return ListTile(
              title: Text(result['symbol'] ?? ''),
              subtitle: Text(result['description'] ?? ''),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StockDetails(
                      symbol: result['symbol'] ?? '',
                      description: result['description'] ?? '',
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // For this implementation, show the same UI as suggestions for the current query
    return buildSuggestions(context);
  }
}
