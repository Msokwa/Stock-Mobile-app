import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stock_app/services/env.dart';
import 'package:stock_app/stockdetails.dart';

class Watchlist extends StatefulWidget {
  const Watchlist({super.key});

  @override
  State<Watchlist> createState() => _WatchlistState();
}

class _WatchlistState extends State<Watchlist> {
  final String apiKey = Env.finnhubApiKey;
  final TextEditingController _searchController = TextEditingController();

  List<String> _savedTickers = [];
  List<StockWatchInfo> _watchlistData = [];
  bool _isLoadingWatchlist = false;
  bool _isGridView = false;

  Future<List<String>> _loadSavedTickers() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('watchlist_symbols');
    if (stored == null || stored.isEmpty) {
      return ['AAPL', 'TSLA', 'NVDA', 'MSFT', 'AMZN', 'INTC'];
    }
    return stored.map((symbol) => symbol.trim().toUpperCase()).toList();
  }

  Future<void> _saveWatchlist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('watchlist_symbols', _savedTickers);
  }

  @override
  void initState() {
    super.initState();
    _fetchCompleteWatchlist();
  }

  Future<StockWatchInfo> _fetchSingleStockData(String symbol) async {
    final profileUrl =
        'https://finnhub.io/api/v1/stock/profile2?symbol=$symbol&token=$apiKey';
    final quoteUrl =
        'https://finnhub.io/api/v1/quote?symbol=$symbol&token=$apiKey';

    final responses = await Future.wait([
      http.get(Uri.parse(profileUrl)),
      http.get(Uri.parse(quoteUrl)),
    ]);

    final profileJson = jsonDecode(responses[0].body);
    final quoteJson = jsonDecode(responses[1].body);

    return StockWatchInfo(
      symbol: symbol.toUpperCase(),
      name: profileJson['name'] ?? 'Unknown Company',
      logo: profileJson['logo'] ?? '',
      price: (quoteJson['c'] as num).toDouble(),
      percentChange: (quoteJson['dp'] as num).toDouble(),
    );
  }

  Future<void> _fetchCompleteWatchlist() async {
    setState(() => _isLoadingWatchlist = true);
    try {
      _savedTickers = await _loadSavedTickers();
      List<StockWatchInfo> temp = [];
      for (String ticker in _savedTickers) {
        final data = await _fetchSingleStockData(ticker);
        temp.add(data);
      }
      setState(() {
        _watchlistData = temp;
      });
    } catch (e) {
      debugPrint("Error fetching watchlist: $e");
    } finally {
      setState(() => _isLoadingWatchlist = false);
    }
  }

  void _addNewStock(String symbol) async {
    if (symbol.isEmpty) return;
    final cleanSymbol = symbol.trim().toUpperCase();

    if (_savedTickers.contains(cleanSymbol)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stock already in watchlist')),
        );
      }
      return;
    }

    _searchController.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Searching and adding $cleanSymbol...')),
      );
    }

    try {
      final newStock = await _fetchSingleStockData(cleanSymbol);
      if (mounted) {
        setState(() {
          _savedTickers.add(cleanSymbol);
          _watchlistData.add(newStock);
        });
        await _saveWatchlist();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stock symbol not found or network error'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121824),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'STOCKSCOPE',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        backgroundColor: const Color(0xFF1A2232),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search company or symbol (e.g. GOOG)...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.white54,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1A2232),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (val) => _addNewStock(val),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _addNewStock(_searchController.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Watchlist (${_watchlistData.length})',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isGridView = !_isGridView;
                    });
                  },
                  icon: Icon(
                    _isGridView ? Icons.view_list : Icons.grid_3x3,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoadingWatchlist
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF00C853),
                      ),
                    )
                  : _isGridView
                  ? GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.85,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: _watchlistData.length,
                      itemBuilder: (context, index) {
                        final stock = _watchlistData[index];
                        final bool isPositive = stock.percentChange >= 0;

                        return _buildGridStockCard(stock, isPositive);
                      },
                    )
                  : ListView.builder(
                      itemCount: _watchlistData.length,
                      itemBuilder: (context, index) {
                        final stock = _watchlistData[index];
                        final bool isPositive = stock.percentChange >= 0;

                        return _buildListStockCard(stock, isPositive);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListStockCard(StockWatchInfo stock, bool isPositive) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                StockDetails(symbol: stock.symbol, description: stock.name),
          ),
        ).then((_) {
          if (mounted) {
            _fetchCompleteWatchlist();
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2232),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${stock.name} (${stock.symbol})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stock.symbol,
                    style: const TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${stock.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${isPositive ? '+' : ''}${stock.percentChange.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: isPositive
                        ? const Color(0xFF00C853)
                        : const Color(0xFFFF3D00),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridStockCard(StockWatchInfo stock, bool isPositive) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                StockDetails(symbol: stock.symbol, description: stock.name),
          ),
        ).then((_) {
          if (mounted) {
            _fetchCompleteWatchlist();
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A2232),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            Text(
              stock.symbol,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              stock.name,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
            const SizedBox(height: 8),
            Text(
              '\$${stock.price.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${isPositive ? '+' : ''}${stock.percentChange.toStringAsFixed(2)}%',
              style: TextStyle(
                color: isPositive
                    ? const Color(0xFF00C853)
                    : const Color(0xFFFF3D00),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StockWatchInfo {
  final String symbol;
  final String name;
  final String logo;
  final double price;
  final double percentChange;

  StockWatchInfo({
    required this.symbol,
    required this.name,
    required this.logo,
    required this.price,
    required this.percentChange,
  });
}
