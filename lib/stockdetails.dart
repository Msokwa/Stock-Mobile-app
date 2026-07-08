import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:stock_app/services/portfolio_service.dart';
import 'package:stock_app/payment.dart';
import 'package:stock_app/watchlist.dart';
import 'package:stock_app/home.dart';

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
  ChartRange _selectedRange = ChartRange.week;
  bool _isAddingToWatchlist = false;

  @override
  void initState() {
    super.initState();
    // Show UI immediately; fetch details in background and update when ready
    _loadFuture = Future.value();
    _loadStockDetails();
  }

  Future<void> _loadStockDetails() async {
    setState(() {
      final seed = widget.symbol.trim().isEmpty
          ? 100.0
          : 100.0 +
                (widget.symbol.codeUnits.fold<int>(
                      0,
                      (sum, value) => sum + value,
                    ) %
                    25);
      _currentPrice = seed + 4.35;
      _change = 1.18;
      _percentChange = 1.09;
    });

    await _loadRangeData(_selectedRange);
  }

  Future<void> _loadRangeData(ChartRange range) async {
    setState(() {
      _spots = _dummySpotsForRange(range);
      _historyTimestamps = List<int>.generate(
        _spots.length,
        (index) =>
            DateTime.now()
                .subtract(Duration(minutes: (_spots.length - index) * 15))
                .millisecondsSinceEpoch ~/
            1000,
      );
    });
  }

  Future<void> _addToWatchlist() async {
    if (_isAddingToWatchlist) return;

    setState(() {
      _isAddingToWatchlist = true;
    });

    try {
      final symbol = widget.symbol.trim().toUpperCase();
      if (symbol.isEmpty) {
        _showWatchlistFeedback('Unable to add an empty symbol to watchlist');
        return;
      }

      final existing = await loadWatchlistSymbols();
      final alreadySaved = existing.contains(symbol);

      await addWatchlistSymbol(symbol);

      _showWatchlistFeedback(
        alreadySaved
            ? '$symbol is already in your watchlist'
            : '$symbol added to your watchlist',
      );
    } catch (error) {
      debugPrint('Unable to add stock to watchlist: $error');
      _showWatchlistFeedback('Unable to add stock to watchlist');
    } finally {
      if (mounted) {
        setState(() {
          _isAddingToWatchlist = false;
        });
      }
    }
  }

  void _showWatchlistFeedback(String message) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            if (!mounted) return;
            messenger.hideCurrentSnackBar();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Watchlist()),
            );
          },
        ),
      ),
    );
  }

  List<FlSpot> _defaultSpots() => const [
    FlSpot(1, 0),
    FlSpot(2, 0.5),
    FlSpot(3, 0.8),
    FlSpot(4, 1),
  ];

  List<FlSpot> _dummySpotsForRange(ChartRange range) {
    switch (range) {
      case ChartRange.day:
        return const [
          FlSpot(0, 101.2),
          FlSpot(1, 102.8),
          FlSpot(2, 101.9),
          FlSpot(3, 103.7),
          FlSpot(4, 104.2),
          FlSpot(5, 103.5),
          FlSpot(6, 105.1),
        ];
      case ChartRange.week:
        return const [
          FlSpot(0, 99.5),
          FlSpot(1, 100.4),
          FlSpot(2, 101.1),
          FlSpot(3, 102.7),
          FlSpot(4, 103.2),
          FlSpot(5, 104.5),
          FlSpot(6, 105.0),
        ];
      case ChartRange.month:
        return const [
          FlSpot(0, 96.4),
          FlSpot(1, 97.1),
          FlSpot(2, 98.8),
          FlSpot(3, 99.6),
          FlSpot(4, 100.9),
          FlSpot(5, 102.3),
          FlSpot(6, 103.1),
          FlSpot(7, 104.7),
        ];
      case ChartRange.year:
        return const [
          FlSpot(0, 88.0),
          FlSpot(1, 90.3),
          FlSpot(2, 92.8),
          FlSpot(3, 95.4),
          FlSpot(4, 97.2),
          FlSpot(5, 99.1),
          FlSpot(6, 101.4),
          FlSpot(7, 103.6),
        ];
      case ChartRange.twoYears:
        return const [
          FlSpot(0, 80.2),
          FlSpot(1, 83.5),
          FlSpot(2, 85.9),
          FlSpot(3, 89.4),
          FlSpot(4, 92.6),
          FlSpot(5, 95.1),
          FlSpot(6, 98.3),
          FlSpot(7, 101.0),
        ];
    }
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
        leading: IconButton(
          iconSize: 23,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Home()),
          ),
        ),
        backgroundColor: const Color(0xFF091625),
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
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _isAddingToWatchlist
                                        ? null
                                        : _addToWatchlist,
                                    icon: _isAddingToWatchlist
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.star_border),
                                    label: Text(
                                      _isAddingToWatchlist
                                          ? 'Adding...'
                                          : 'Add to Watchlist',
                                    ),
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
                              ],
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
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xff091625),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white12,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'About this stock',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.description,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildAboutRow('Symbol', widget.symbol),
                                const SizedBox(height: 8),
                                _buildAboutRow(
                                  'Overview',
                                  'This card can hold company background, business focus, and other key stock notes.',
                                ),
                              ],
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

  Widget _buildAboutRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
