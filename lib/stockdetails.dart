import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:stock_app/services/env.dart';
import 'package:stock_app/services/historical_data_service.dart';
import 'package:stock_app/services/portfolio_service.dart';
import 'package:stock_app/watchlist.dart';
import 'package:stock_app/payment.dart';

enum ChartRange { day, week, month, year, twoYears }

class StockDetails extends StatefulWidget {
  final String symbol;
  final String description;

  const StockDetails({
    super.key,
    required this.symbol,
    required this.description,
  });

  @override
  State<StockDetails> createState() => _StockDetailsState();
}

class _StockDetailsState extends State<StockDetails> {
  late Future<void> _loadFuture;
  List<FlSpot> _spots = [];
  List<int> _historyTimestamps = [];
  double? _currentPrice;
  double? _change;
  double? _percentChange;
  double? _openPrice;
  double? _highPrice;
  double? _lowPrice;
  Map<String, dynamic>? _profile;
  String? _loadedSymbol;
  DateTime? _lastUpdated;
  ChartRange _selectedRange = ChartRange.week;
  bool _isRangeLoading = false;
  bool _isRefreshing = false;
  String? _rangeError;
  String? _loadError;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadStockDetails();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadStockDetails() async {
    setState(() {
      _loadError = null;
      _rangeError = null;
    });

    final String apiKey = Env.finnhubApiKey;

    final symbolCandidates = <String>{
      widget.symbol.trim().toUpperCase(),
      _alternateSymbol(widget.symbol),
      _stripSymbolSuffix(widget.symbol),
    }..removeWhere((s) => s.isEmpty);

    final searchCandidates = await _searchSymbolCandidates(widget.symbol);
    symbolCandidates.addAll(searchCandidates);

    for (final symbol in symbolCandidates) {
      try {
        final profileUrl =
            'https://finnhub.io/api/v1/stock/profile2?symbol=${Uri.encodeQueryComponent(symbol)}&token=$apiKey';
        final quoteUrl =
            'https://finnhub.io/api/v1/quote?symbol=${Uri.encodeQueryComponent(symbol)}&token=$apiKey';

        debugPrint('Fetching profile and quote for $symbol');
        final profileResponse = await http
            .get(Uri.parse(profileUrl))
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () =>
                  throw TimeoutException('Profile request timed out'),
            );
        final quoteResponse = await http
            .get(Uri.parse(quoteUrl))
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () =>
                  throw TimeoutException('Quote request timed out'),
            );

        if (quoteResponse.statusCode != 200) {
          debugPrint(
            'Quote response error for $symbol: ${quoteResponse.statusCode}',
          );
          continue;
        }

        final quoteJson =
            json.decode(quoteResponse.body) as Map<String, dynamic>;
        final currentPrice = (quoteJson['c'] as num?)?.toDouble();
        final change = (quoteJson['d'] as num?)?.toDouble();
        final percentChange = (quoteJson['dp'] as num?)?.toDouble();
        final openPrice = (quoteJson['o'] as num?)?.toDouble();
        final highPrice = (quoteJson['h'] as num?)?.toDouble();
        final lowPrice = (quoteJson['l'] as num?)?.toDouble();

        if (currentPrice == null || currentPrice == 0.0) {
          debugPrint('Invalid price for $symbol: $currentPrice');
          continue;
        }

        setState(() {
          if (profileResponse.statusCode == 200) {
            _profile =
                json.decode(profileResponse.body) as Map<String, dynamic>;
          }
          _currentPrice = currentPrice;
          _change = change;
          _percentChange = percentChange;
          _openPrice = openPrice;
          _highPrice = highPrice;
          _lowPrice = lowPrice;
          _loadedSymbol = symbol;
          _lastUpdated = DateTime.now();
        });

        await _loadRangeData(_selectedRange, symbol: symbol);
        _startAutoRefresh();
        return;
      } catch (_) {
        continue;
      }
    }

    setState(() {
      _loadError =
          'Unable to load quote data for ${widget.symbol}. Please try another stock.';
      _spots = _fallbackSpots();
      _historyTimestamps = [];
    });
  }

  Future<void> _loadRangeData(ChartRange range, {String? symbol}) async {
    setState(() {
      _isRangeLoading = true;
      _rangeError = null;
    });

    final requestSymbol = (symbol ?? _loadedSymbol ?? widget.symbol).trim();

    try {
      debugPrint('Loading chart data for $requestSymbol');

      List<HistoricalDataPoint> dataPoints;

      if (range == ChartRange.year) {
        dataPoints = await HistoricalDataService.fetchOneYearData(
          requestSymbol,
        );
      } else {
        final duration = _durationForRange(range);
        dataPoints = await HistoricalDataService.fetchDataForRange(
          requestSymbol,
          duration,
        );
      }

      if (dataPoints.isEmpty) {
        throw Exception('No historical data available');
      }

      // Convert to FlSpot points for the chart
      final List<FlSpot> spots = dataPoints
          .asMap()
          .entries
          .map((entry) => FlSpot(entry.key.toDouble(), entry.value.close))
          .toList();

      final timestamps = dataPoints
          .map((p) => p.timestamp.millisecondsSinceEpoch ~/ 1000)
          .toList();

      debugPrint('Successfully loaded ${spots.length} data points');

      setState(() {
        _spots = spots;
        _historyTimestamps = timestamps;
        _rangeError = null;
      });
    } catch (error) {
      debugPrint('Error loading chart data: $error');
      setState(() {
        _rangeError = _currentPrice != null
            ? 'Showing current quote data; historical chart may be unavailable.'
            : 'Unable to load chart data';
        _spots = _fallbackSpots();
        _historyTimestamps = [];
      });
    } finally {
      setState(() {
        _isRangeLoading = false;
      });
    }
  }

  String _alternateSymbol(String symbol) {
    if (!symbol.contains('.')) return symbol;
    final parts = symbol.split('.');
    if (parts.length != 2) return symbol;

    final base = parts[0].toUpperCase();
    final suffix = parts[1].toUpperCase();
    final exchangeMap = <String, String>{
      'NS': 'NSE',
      'BSE': 'BSE',
      'BO': 'BSE',
      'L': 'LSE',
      'SS': 'SSE',
      'HK': 'HKEX',
      'SZ': 'SHE',
      'TO': 'TSE',
      'TW': 'TWO',
    };

    final exchange = exchangeMap[suffix] ?? suffix;
    return '$exchange:$base';
  }

  String _stripSymbolSuffix(String symbol) {
    if (!symbol.contains('.')) return symbol;
    return symbol.split('.').first.toUpperCase();
  }

  Future<List<String>> _searchSymbolCandidates(String query) async {
    final candidates = <String>[];
    if (query.trim().isEmpty) return candidates;

    final String apiKey = Env.finnhubApiKey;
    final searchQuery = query.replaceAll('.', ' ').trim();
    final searchUrl =
        'https://finnhub.io/api/v1/search?q=${Uri.encodeQueryComponent(searchQuery)}&token=$apiKey';

    try {
      final response = await http
          .get(Uri.parse(searchUrl))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Search request timed out'),
          );
      if (response.statusCode != 200) {
        debugPrint('Search API error: ${response.statusCode}');
        return candidates;
      }

      final body = json.decode(response.body) as Map<String, dynamic>;
      final results = (body['result'] as List<dynamic>?) ?? [];
      for (final item in results.cast<Map<String, dynamic>>()) {
        final symbol = (item['symbol'] as String?)?.trim();
        if (symbol != null && symbol.isNotEmpty) {
          candidates.add(symbol.toUpperCase());
        }
      }
    } catch (e) {
      debugPrint('Error searching symbols: $e');
      // ignore search errors and continue with direct symbol candidates
    }

    return candidates;
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _refreshLiveData();
    });
  }

  Future<void> _refreshLiveData() async {
    if (!mounted || _loadedSymbol == null) return;

    setState(() {
      _isRefreshing = true;
      _rangeError = null;
    });

    final String apiKey = Env.finnhubApiKey;
    final quoteUrl =
        'https://finnhub.io/api/v1/quote?symbol=${Uri.encodeQueryComponent(_loadedSymbol!)}&token=$apiKey';

    try {
      final quoteResponse = await http
          .get(Uri.parse(quoteUrl))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Quote refresh timed out'),
          );
      if (quoteResponse.statusCode != 200) {
        throw Exception('Unable to refresh quote: ${quoteResponse.statusCode}');
      }

      final quoteJson = json.decode(quoteResponse.body) as Map<String, dynamic>;
      final currentPrice = (quoteJson['c'] as num?)?.toDouble();
      if (currentPrice != null) {
        setState(() {
          _currentPrice = currentPrice;
          _change = (quoteJson['d'] as num?)?.toDouble();
          _percentChange = (quoteJson['dp'] as num?)?.toDouble();
          _openPrice = (quoteJson['o'] as num?)?.toDouble();
          _highPrice = (quoteJson['h'] as num?)?.toDouble();
          _lowPrice = (quoteJson['l'] as num?)?.toDouble();
          _lastUpdated = DateTime.now();
        });
      }

      if (_selectedRange == ChartRange.day ||
          _selectedRange == ChartRange.week) {
        await _loadRangeData(_selectedRange, symbol: _loadedSymbol);
      }
    } catch (e) {
      debugPrint('Error refreshing live data: $e');
      // ignore refresh errors; keep existing chart data
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  String _formatUpdatedAt(DateTime updatedAt) {
    final local = updatedAt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  Duration _durationForRange(ChartRange range) {
    switch (range) {
      case ChartRange.day:
        return const Duration(days: 1);
      case ChartRange.week:
        return const Duration(days: 7);
      case ChartRange.month:
        return const Duration(days: 30);
      case ChartRange.year:
        return const Duration(days: 365);
      case ChartRange.twoYears:
        return const Duration(days: 730);
    }
  }

  Future<void> _addToWatchlist() async {
    try {
      final symbol = widget.symbol.trim().toUpperCase();
      await addWatchlistSymbol(symbol);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$symbol added to your watchlist'),
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Watchlist()),
                ).then((_) {
                  if (mounted) {
                    _loadStockDetails();
                  }
                });
              },
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to add stock to watchlist')),
        );
      }
    }
  }

  List<FlSpot> _defaultSpots() => const [
    FlSpot(1, 0),
    FlSpot(2, 0.5),
    FlSpot(3, 0.8),
    FlSpot(4, 1),
  ];

  List<FlSpot> _fallbackSpots() {
    if (_currentPrice == null) return _defaultSpots();
    final low = _lowPrice ?? _currentPrice! * 0.98;
    final open = _openPrice ?? _currentPrice! * 0.995;
    final high = _highPrice ?? _currentPrice! * 1.02;
    final close = _currentPrice!;

    return [FlSpot(0, low), FlSpot(1, open), FlSpot(2, close), FlSpot(3, high)];
  }

  String _rangeLabel(ChartRange range) {
    switch (range) {
      case ChartRange.day:
        return '1D';
      case ChartRange.week:
        return '1W';
      case ChartRange.month:
        return '1M';
      case ChartRange.year:
        return '1Y';
      case ChartRange.twoYears:
        return '2Y';
    }
  }

  String _xLabel(double value, ChartRange range) {
    if (_historyTimestamps.isEmpty) {
      return value.toInt().toString();
    }

    final index = value.toInt().clamp(0, _historyTimestamps.length - 1);
    final timestamp = _historyTimestamps[index];
    final date = DateTime.fromMillisecondsSinceEpoch(
      timestamp * 1000,
      isUtc: true,
    ).toLocal();

    switch (range) {
      case ChartRange.day:
        return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      case ChartRange.week:
        return '${date.month}/${date.day}';
      case ChartRange.month:
        return '${date.month}/${date.day}';
      case ChartRange.year:
      case ChartRange.twoYears:
        return '${date.month}/${date.year % 100}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final spots = _spots.isNotEmpty ? _spots : _defaultSpots();
    final minY = spots.map((e) => e.y).reduce(min);
    final maxY = spots.map((e) => e.y).reduce(max);
    final yDelta = maxY - minY;
    final chartMinY = yDelta > 0 ? minY - yDelta * 0.1 : minY - 1;
    final chartMaxY = yDelta > 0 ? maxY + yDelta * 0.1 : maxY + 1;
    final yInterval = max(1.0, yDelta / 4);
    final xInterval = spots.length > 1
        ? max(1.0, (spots.last.x - spots.first.x) / 6)
        : 1.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF191625),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(widget.symbol),
      ),
      body: FutureBuilder<void>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (_loadError != null && _currentPrice == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _loadError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _loadFuture = _loadStockDetails();
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.description,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                Card(
                  elevation: 0,
                  color: const Color(0xff091625),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: Colors.green.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: DefaultTextStyle(
                    style: const TextStyle(color: Colors.white),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                widget.symbol,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _currentPrice != null
                                        ? '\$${_currentPrice!.toStringAsFixed(2)}'
                                        : 'N/A',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _change != null
                                        ? '${_change! >= 0 ? '+' : ''}${_change!.toStringAsFixed(2)}'
                                        : '',
                                    style: TextStyle(
                                      color: (_change ?? 0) >= 0
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                  Text(
                                    _percentChange != null
                                        ? '${_percentChange!.toStringAsFixed(2)}%'
                                        : '',
                                    style: TextStyle(
                                      color: (_percentChange ?? 0) >= 0
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: ChartRange.values.map((range) {
                              final selected = range == _selectedRange;
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: selected
                                          ? Colors.green
                                          : Colors.white,
                                      foregroundColor: selected
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                    onPressed: () {
                                      if (_selectedRange == range) return;
                                      setState(() {
                                        _selectedRange = range;
                                      });
                                      _loadRangeData(range);
                                    },
                                    child: Text(_rangeLabel(range)),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 40,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xff091625),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color.fromRGBO(76, 175, 80, 0.3),
                                width: 1,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _lastUpdated != null
                                      ? 'Live • updated ${_formatUpdatedAt(_lastUpdated!)}'
                                      : 'Live data',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (_isRefreshing)
                                  const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.green,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_isRangeLoading)
                            const SizedBox(
                              height: 260,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            )
                          else
                            Container(
                              height: 260,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xff091625),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: LineChart(
                                LineChartData(
                                  minX: spots.first.x,
                                  maxX: spots.last.x,
                                  minY: chartMinY,
                                  maxY: chartMaxY,
                                  titlesData: FlTitlesData(
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 30,
                                        interval: xInterval,
                                        getTitlesWidget: (value, meta) {
                                          final label = _xLabel(
                                            value,
                                            _selectedRange,
                                          );
                                          return Text(
                                            label,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 40,
                                        interval: yInterval,
                                        getTitlesWidget: (value, meta) {
                                          return Text(
                                            '\$${value.toInt()}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    topTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                  ),
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    getDrawingHorizontalLine: (value) => FlLine(
                                      color: Colors.grey.withValues(alpha: 0.2),
                                      strokeWidth: 1,
                                    ),
                                  ),
                                  borderData: FlBorderData(
                                    show: true,
                                    border: Border.all(
                                      color: Colors.green,
                                      width: 1,
                                    ),
                                  ),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: spots,
                                      isCurved: true,
                                      barWidth: 3,
                                      color: Colors.green,
                                      dotData: FlDotData(show: false),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: Colors.green.withValues(
                                          alpha: 0.25,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (_rangeError != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _rangeError!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                          if (_loadError != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _loadError!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _addToWatchlist,
                              icon: const Icon(Icons.star_border),
                              label: const Text('Add to Watchlist'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => Payment(
                                          symbol: widget.symbol,
                                          description: widget.description,
                                          price: _currentPrice ?? 0,
                                          action: 'buy',
                                          shares: 1,
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00C853),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Buy',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => Payment(
                                          symbol: widget.symbol,
                                          description: widget.description,
                                          price: _currentPrice ?? 0,
                                          action: 'sell',
                                          shares: 1,
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Sell',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            title: const Text('Company Name'),
                            subtitle: Text(
                              _profile?['name'] as String? ?? 'N/A',
                            ),
                          ),
                          ListTile(
                            title: const Text('Exchange'),
                            subtitle: Text(
                              _profile?['exchange'] as String? ?? 'N/A',
                            ),
                          ),
                          ListTile(
                            title: const Text('Industry'),
                            subtitle: Text(
                              _profile?['finnhubIndustry'] as String? ?? 'N/A',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
