import 'package:shared_preferences/shared_preferences.dart';

const String _portfolioHoldingsKey = 'portfolio_holdings';
const String _portfolioValueKey = 'portfolio_total_value';

Future<Map<String, int>> loadPortfolioHoldings() async {
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

Future<void> savePortfolioHoldings(Map<String, int> holdings) async {
  final prefs = await SharedPreferences.getInstance();
  final serialized = holdings.entries
      .where((entry) => entry.value > 0)
      .map((entry) => '${entry.key.toUpperCase()}:${entry.value}')
      .toList();

  await prefs.setStringList(_portfolioHoldingsKey, serialized);
}

Future<void> addPortfolioHolding(String symbol, {int shares = 1}) async {
  final normalizedSymbol = symbol.trim().toUpperCase();
  if (normalizedSymbol.isEmpty) {
    return;
  }

  final holdings = await loadPortfolioHoldings();
  final currentShares = holdings[normalizedSymbol] ?? 0;
  holdings[normalizedSymbol] = currentShares + shares;
  await savePortfolioHoldings(holdings);
  await updatePortfolioValue(holdings);
}

Future<void> removePortfolioHolding(String symbol, {int shares = 1}) async {
  final normalizedSymbol = symbol.trim().toUpperCase();
  if (normalizedSymbol.isEmpty) {
    return;
  }

  final holdings = await loadPortfolioHoldings();
  final currentShares = holdings[normalizedSymbol] ?? 0;
  final newShares = (currentShares - shares).clamp(0, currentShares);

  if (newShares <= 0) {
    holdings.remove(normalizedSymbol);
  } else {
    holdings[normalizedSymbol] = newShares;
  }

  await savePortfolioHoldings(holdings);
  await updatePortfolioValue(holdings);
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
