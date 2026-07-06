import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String _portfolioHoldingsKey = 'portfolio_holdings';
const String _portfolioValueKey = 'portfolio_total_value';
const String _watchlistSymbolsKey = 'watchlist_symbols';

final SupabaseClient _supabase = Supabase.instance.client;

Map<String, int> mergeHoldingShares(
  Map<String, int> holdings,
  String symbol,
  int sharesDelta, {
  bool allowZero = false,
}) {
  final normalizedSymbol = symbol.trim().toUpperCase();
  if (normalizedSymbol.isEmpty) {
    return holdings;
  }

  final updated = <String, int>{...holdings};
  final currentShares = updated[normalizedSymbol] ?? 0;
  final nextShares = currentShares + sharesDelta;

  if (nextShares <= 0 && !allowZero) {
    updated.remove(normalizedSymbol);
  } else if (nextShares > 0) {
    updated[normalizedSymbol] = nextShares;
  } else {
    updated.remove(normalizedSymbol);
  }

  return updated;
}

String? _currentUserId() => _supabase.auth.currentUser?.id;

bool _canUseSupabase() =>
    _supabase.auth.currentSession != null && _currentUserId() != null;

Future<Map<String, int>> loadPortfolioHoldings() async {
  if (_canUseSupabase()) {
    try {
      final data = await _supabase
          .from('portfolio_holdings')
          .select('symbol, shares')
          .eq('user_id', _currentUserId()!);

      final holdings = <String, int>{};
      for (final row in data as List<dynamic>) {
        final map = row as Map<String, dynamic>;
        final symbol = (map['symbol'] as String?)?.trim().toUpperCase();
        final shares = (map['shares'] as num?)?.toInt() ?? 0;
        if (symbol != null && symbol.isNotEmpty && shares > 0) {
          holdings[symbol] = shares;
        }
      }

      if (holdings.isNotEmpty) {
        await _persistPortfolioHoldingsLocally(holdings);
        await updatePortfolioValue(holdings);
        return holdings;
      }
    } catch (error) {
      debugPrint('Unable to load portfolio from Supabase: $error');
    }
  }

  return _loadPortfolioHoldingsFromLocal();
}

Future<void> savePortfolioHoldings(Map<String, int> holdings) async {
  await _persistPortfolioHoldingsLocally(holdings);
}

Future<void> addPortfolioHolding(String symbol, {int shares = 1}) async {
  await applyPortfolioTransaction(symbol, action: 'buy', shares: shares);
}

Future<void> removePortfolioHolding(String symbol, {int shares = 1}) async {
  await applyPortfolioTransaction(symbol, action: 'sell', shares: shares);
}

Future<void> applyPortfolioTransaction(
  String symbol, {
  required String action,
  int shares = 1,
}) async {
  final normalizedSymbol = symbol.trim().toUpperCase();
  if (normalizedSymbol.isEmpty || shares <= 0) {
    return;
  }

  final delta = action.toLowerCase() == 'buy' ? shares : -shares;
  final holdings = await loadPortfolioHoldings();
  final updated = mergeHoldingShares(
    holdings,
    normalizedSymbol,
    delta,
    allowZero: true,
  );
  await _persistPortfolioHoldingsLocally(updated);

  if (_canUseSupabase()) {
    try {
      final userId = _currentUserId()!;
      final nextShares = updated[normalizedSymbol] ?? 0;

      if (nextShares <= 0) {
        await _supabase
            .from('portfolio_holdings')
            .delete()
            .eq('user_id', userId)
            .eq('symbol', normalizedSymbol);
      } else {
        await _supabase.from('portfolio_holdings').upsert({
          'user_id': userId,
          'symbol': normalizedSymbol,
          'shares': nextShares,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }, onConflict: 'user_id,symbol');
      }

      await _supabase.from('portfolio_transactions').insert({
        'user_id': userId,
        'symbol': normalizedSymbol,
        'action': action.toLowerCase(),
        'shares': shares,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (error) {
      debugPrint('Unable to sync portfolio transaction to Supabase: $error');
    }
  }

  await updatePortfolioValue(updated);
}

Future<void> updatePortfolioValue(Map<String, int> holdings) async {
  double totalValue = 0.0;

  for (final entry in holdings.entries) {
    final price = _getStockPrice(entry.key);
    totalValue += price * entry.value;
  }

  final prefs = await SharedPreferences.getInstance();
  await prefs.setDouble(_portfolioValueKey, totalValue);
}

Future<double> getPortfolioValue() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getDouble(_portfolioValueKey) ?? 0.0;
}

Future<double> calculatePortfolioValue(Map<String, int> holdings) async {
  double totalValue = 0.0;

  for (final entry in holdings.entries) {
    final price = _getStockPrice(entry.key);
    totalValue += price * entry.value;
  }

  return totalValue;
}

Future<List<String>> loadWatchlistSymbols() async {
  if (_canUseSupabase()) {
    try {
      final data = await _supabase
          .from('watchlist_items')
          .select('symbol')
          .eq('user_id', _currentUserId()!);

      final symbols = <String>{};
      for (final row in data as List<dynamic>) {
        final map = row as Map<String, dynamic>;
        final symbol = (map['symbol'] as String?)?.trim().toUpperCase();
        if (symbol != null && symbol.isNotEmpty) {
          symbols.add(symbol);
        }
      }

      if (symbols.isNotEmpty) {
        final list = symbols.toList()..sort();
        await saveWatchlistSymbols(list);
        return list;
      }
    } catch (error) {
      debugPrint('Unable to load watchlist from Supabase: $error');
    }
  }

  return _loadWatchlistSymbolsFromLocal();
}

Future<void> addWatchlistSymbol(String symbol) async {
  final normalizedSymbol = symbol.trim().toUpperCase();
  if (normalizedSymbol.isEmpty) {
    return;
  }

  final existing = await loadWatchlistSymbols();
  if (existing.contains(normalizedSymbol)) {
    return;
  }

  final updated = [...existing, normalizedSymbol]..sort();
  await saveWatchlistSymbols(updated);

  if (_canUseSupabase()) {
    try {
      await _supabase.from('watchlist_items').upsert({
        'user_id': _currentUserId()!,
        'symbol': normalizedSymbol,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id,symbol');
    } catch (error) {
      debugPrint('Unable to sync watchlist to Supabase: $error');
    }
  }
}

Future<void> removeWatchlistSymbol(String symbol) async {
  final normalizedSymbol = symbol.trim().toUpperCase();
  if (normalizedSymbol.isEmpty) {
    return;
  }

  final existing = await loadWatchlistSymbols();
  final updated = existing.where((entry) => entry != normalizedSymbol).toList();
  await saveWatchlistSymbols(updated);

  if (_canUseSupabase()) {
    try {
      await _supabase
          .from('watchlist_items')
          .delete()
          .eq('user_id', _currentUserId()!)
          .eq('symbol', normalizedSymbol);
    } catch (error) {
      debugPrint('Unable to remove watchlist item from Supabase: $error');
    }
  }
}

Future<void> _persistPortfolioHoldingsLocally(Map<String, int> holdings) async {
  final prefs = await SharedPreferences.getInstance();
  final serialized = holdings.entries
      .where((entry) => entry.value > 0)
      .map((entry) => '${entry.key.toUpperCase()}:${entry.value}')
      .toList();

  await prefs.setStringList(_portfolioHoldingsKey, serialized);
}

Future<Map<String, int>> _loadPortfolioHoldingsFromLocal() async {
  final prefs = await SharedPreferences.getInstance();
  final storedEntries =
      prefs.getStringList(_portfolioHoldingsKey) ?? <String>[];

  final holdings = <String, int>{};
  for (final entry in storedEntries) {
    final parts = entry.split(':');
    if (parts.length != 2) {
      continue;
    }

    final symbol = parts[0].trim().toUpperCase();
    final shares = int.tryParse(parts[1].trim()) ?? 0;
    if (symbol.isNotEmpty && shares > 0) {
      holdings[symbol] = shares;
    }
  }

  return holdings;
}

Future<void> saveWatchlistSymbols(List<String> symbols) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList(
    _watchlistSymbolsKey,
    symbols.map((symbol) => symbol.toUpperCase()).toList(),
  );
}

Future<List<String>> _loadWatchlistSymbolsFromLocal() async {
  final prefs = await SharedPreferences.getInstance();
  final stored = prefs.getStringList(_watchlistSymbolsKey);
  if (stored == null || stored.isEmpty) {
    return ['AAPL', 'TSLA', 'NVDA', 'MSFT', 'AMZN'];
  }
  return stored.map((symbol) => symbol.trim().toUpperCase()).toList();
}

double _getStockPrice(String symbol) {
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
