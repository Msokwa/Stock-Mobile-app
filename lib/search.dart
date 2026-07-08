import 'dart:async';
import 'package:flutter/material.dart';
import 'package:stock_app/services/finnhub_service.dart';
import 'package:stock_app/stockdetails.dart';

class Search extends SearchDelegate<String?> {
  static const int _maxRetries = 3;
  static const int _minQueryLength = 2;
  static const Duration _baseBackoff = Duration(milliseconds: 500);
  static final Map<String, List<Map<String, String>>> _searchCache = {};
  static final Map<String, Future<List<Map<String, String>>>> _pendingRequests =
      {};
  static DateTime? _lastSearchTime;
  static String _lastSearchQuery = '';

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
    final normalizedQuery = query.trim();
    if (normalizedQuery.length < _minQueryLength) {
      return [];
    }

    if (_searchCache.containsKey(normalizedQuery)) {
      return _searchCache[normalizedQuery]!;
    }

    if (_pendingRequests.containsKey(normalizedQuery)) {
      return _pendingRequests[normalizedQuery]!;
    }

    final requestFuture = _performSearch(normalizedQuery);
    _pendingRequests[normalizedQuery] = requestFuture;
    try {
      final results = await requestFuture;
      _searchCache[normalizedQuery] = results;
      return results;
    } finally {
      _pendingRequests.remove(normalizedQuery);
      _lastSearchTime = DateTime.now();
      _lastSearchQuery = normalizedQuery;
    }
  }

  Future<List<Map<String, String>>> _performSearch(
    String normalizedQuery,
  ) async {
    final minimumDelay = const Duration(milliseconds: 400);
    if (_lastSearchTime != null &&
        DateTime.now().difference(_lastSearchTime!) < minimumDelay &&
        normalizedQuery != _lastSearchQuery) {
      await Future.delayed(minimumDelay);
    }

    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final results = await FinnhubService.searchTickers(
          normalizedQuery,
          limit: 20,
        );
        if (results.isNotEmpty || attempt == _maxRetries - 1) {
          return results;
        }
        await Future.delayed(_baseBackoff * (attempt + 1));
      } catch (e) {
        if (attempt == _maxRetries - 1) rethrow;
        await Future.delayed(_baseBackoff * (attempt + 1));
      }
    }

    return [];
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
    if (query.trim().length < _minQueryLength) {
      return const Center(child: Text('Type at least 2 characters to search'));
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
