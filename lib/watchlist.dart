import 'package:flutter/material.dart';

import 'package:stock_app/services/finnhub_service.dart';
import 'package:stock_app/services/portfolio_service.dart';
import 'package:stock_app/stockdetails.dart';

class Watchlist extends StatefulWidget {
  const Watchlist({super.key});

  @override
  State<Watchlist> createState() => _WatchlistState();
}

class _WatchlistState extends State<Watchlist> {
  final TextEditingController _searchController = TextEditingController();

  List<String> _savedTickers = [];
  List<StockWatchInfo> _watchlistData = [];
  bool _isLoadingWatchlist = false;
  bool _isGridView = false;

  Future<List<String>> _loadSavedTickers() async {
    return loadWatchlistSymbols();
  }

  Future<void> _saveWatchlist() async {
    await saveWatchlistSymbols(_savedTickers);
  }

  void _showWatchlistSnackBar(String message, {Color? backgroundColor}) {
    if (!mounted) return;

    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: backgroundColor,
        ),
      );
  }

  @override
  void initState() {
    super.initState();
    _fetchCompleteWatchlist();
  }

  Future<StockWatchInfo> _fetchSingleStockData(String symbol) async {
    String name = symbol.toUpperCase();
    String logo = '';
    double price = 0.0;
    double percentChange = 0.0;

    // Use Finnhub directly for quote, company profile, and candle data.
    try {
      final profile = await FinnhubService.fetchCompanyProfile(symbol);
      if (profile['name'] != null && profile['name']!.isNotEmpty) {
        name = profile['name']!;
      }
      if (profile['logo'] != null && profile['logo']!.isNotEmpty) {
        logo = profile['logo']!;
      }

      final latestClose = await FinnhubService.fetchLatestClose(symbol);
      if (latestClose != null && latestClose > 0) {
        price = latestClose;
      }

      final now = DateTime.now();
      final from = now.subtract(const Duration(days: 3));
      final points = await FinnhubService.fetchHistorical(symbol, from, now);
      if (points.isNotEmpty) {
        final last = points.last;
        price = price > 0 ? price : last.close;
        if (points.length >= 2) {
          final prev = points[points.length - 2];
          percentChange = ((last.close - prev.close) / prev.close) * 100;
        }
      }
    } catch (_) {}

    // Do not use Finnhub for profile lookup. Keep symbol name and blank logo if Marketstack does not provide metadata.

    return StockWatchInfo(
      symbol: symbol.toUpperCase(),
      name: name,
      logo: logo,
      price: double.parse(price.toStringAsFixed(2)),
      percentChange: double.parse(percentChange.toStringAsFixed(2)),
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

  Future<void> _addResolvedSymbol(String symbol) async {
    final cleanSymbol = symbol.trim().toUpperCase();
    if (cleanSymbol.isEmpty) return;

    if (_savedTickers.contains(cleanSymbol)) {
      _showWatchlistSnackBar('Stock already in watchlist');
      return;
    }

    _searchController.clear();

    try {
      final newStock = await _fetchSingleStockData(cleanSymbol);
      if (mounted) {
        setState(() {
          _savedTickers.add(cleanSymbol);
          _watchlistData.add(newStock);
        });
        await _saveWatchlist();
        await addWatchlistSymbol(cleanSymbol);
        _showWatchlistSnackBar('$cleanSymbol added to watchlist');
      }
    } catch (e) {
      _showWatchlistSnackBar(
        'Stock symbol not found or network error',
        backgroundColor: const Color(0xFFFF3D00),
      );
    }
  }

  Future<void> _addNewStock(String query) async {
    final input = query.trim();
    if (input.isEmpty) return;

    try {
      final directSymbol = input.toUpperCase();
      if (directSymbol.contains(RegExp(r'^[A-Z0-9.:_\-]+$')) &&
          directSymbol.length <= 10) {
        await _addResolvedSymbol(directSymbol);
        return;
      }

      final results = await FinnhubService.searchTickers(input, limit: 8);
      if (!mounted) return;

      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No matching stocks found in Finnhub')),
        );
        return;
      }

      if (results.length == 1) {
        final symbol = results.first['symbol'] ?? '';
        if (symbol.isNotEmpty) {
          await _addResolvedSymbol(symbol);
          return;
        }
      }

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1A2232),
            title: const Text(
              'Choose a symbol',
              style: TextStyle(color: Colors.white),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final item = results[index];
                  final symbol = item['symbol'] ?? '';
                  final description = item['description'] ?? '';
                  return ListTile(
                    title: Text(
                      symbol,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      description,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      if (symbol.isNotEmpty) {
                        await _addResolvedSymbol(symbol);
                      }
                    },
                  );
                },
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Finnhub search failed: $e')));
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const StockDetails(symbol: '', description: ''),
              ),
            );
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
