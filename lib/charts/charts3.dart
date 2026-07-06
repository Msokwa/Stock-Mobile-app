import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stock_app/services/env.dart';
import '../home.dart';

enum ChartRange { week, month, year, twoYears }

class Chart3 extends StatefulWidget {
  final List<FlSpot>? data;
  const Chart3({super.key, this.data});

  @override
  State<Chart3> createState() => _Chart3State();
}

class _Chart3State extends State<Chart3> {
  late Future<void> _loadFuture;
  List<FlSpot> _spots = [];
  double? _currentPrice;
  double? _change;
  double? _percentChange;
  ChartRange _selectedRange = ChartRange.week;
  bool _isRangeLoading = false;
  String? _rangeError;

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadSP500Data();
  }

  Future<void> _loadSP500Data() async {
    final String apiKey = Env.finnhubApiKey;

    final profileUrl =
        'https://finnhub.io/api/v1/stock/profile2?symbol=^GSPC&token=$apiKey';
    final quoteUrl =
        'https://finnhub.io/api/v1/quote?symbol=^GSPC&token=$apiKey';

    final responses = await Future.wait([
      http.get(Uri.parse(profileUrl)),
      http.get(Uri.parse(quoteUrl)),
    ]);

    if (responses.any((response) => response.statusCode != 200)) {
      throw Exception('Failed to load S&P 500 data');
    }

    final quoteJson = json.decode(responses[1].body) as Map<String, dynamic>;

    _currentPrice = (quoteJson['c'] as num?)?.toDouble();
    _change = (quoteJson['d'] as num?)?.toDouble();
    _percentChange = (quoteJson['dp'] as num?)?.toDouble();

    await _loadRangeData(_selectedRange);
  }

  Future<void> _loadRangeData(ChartRange range) async {
    setState(() {
      _isRangeLoading = true;
      _rangeError = null;
    });

    try {
      final spots = _generateLineSpots(range);
      setState(() {
        _spots = spots;
      });
    } catch (error) {
      setState(() {
        _rangeError = 'Unable to load chart data';
        _spots = _defaultSpots();
      });
    } finally {
      setState(() {
        _isRangeLoading = false;
      });
    }
  }

  List<FlSpot> _generateLineSpots(ChartRange range) {
    final base = _currentPrice ?? 5000.0;
    final pointCount = _pointCountForRange(range);
    final trend = _rangeTrend(range);
    final amplitude = max(1.0, base * 0.02);
    final noise = max(0.5, base * 0.01);

    return List<FlSpot>.generate(pointCount, (index) {
      final x = index + 1.0;
      final progress = x / pointCount;
      final drift = (progress - 0.5) * trend;
      final wave = sin(progress * pi * 2) * amplitude;
      final randomNoise = cos(progress * pi * 3) * noise * 0.3;
      final y = max(0.0, base + drift + wave + randomNoise);

      return FlSpot(x, y);
    });
  }

  int _pointCountForRange(ChartRange range) {
    switch (range) {
      case ChartRange.week:
        return 7;
      case ChartRange.month:
        return 30;
      case ChartRange.year:
        return 52;
      case ChartRange.twoYears:
        return 104;
    }
  }

  double _rangeTrend(ChartRange range) {
    switch (range) {
      case ChartRange.week:
        return 5.0;
      case ChartRange.month:
        return 10.0;
      case ChartRange.year:
        return 20.0;
      case ChartRange.twoYears:
        return 40.0;
    }
  }

  List<FlSpot> _defaultSpots() => const [
    FlSpot(1, 0),
    FlSpot(2, 0.5),
    FlSpot(3, 0.8),
    FlSpot(4, 1),
  ];

  String _rangeLabel(ChartRange range) {
    switch (range) {
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
    if (range == ChartRange.week) {
      const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final index = value.toInt() - 1;
      return weekDays[index % weekDays.length];
    }
    if (range == ChartRange.month) {
      return value.toInt() % 5 == 0 ? '${value.toInt()}d' : '';
    }
    if (range == ChartRange.year || range == ChartRange.twoYears) {
      return value.toInt() % 13 == 0 ? '${value.toInt()}' : '';
    }
    return value.toInt().toString();
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final spots = _spots.isNotEmpty ? _spots : _defaultSpots();
        final minY = spots.map((e) => e.y).reduce(min);
        final maxY = spots.map((e) => e.y).reduce(max);
        final yDelta = maxY - minY;
        final chartMinY = yDelta > 0 ? minY - yDelta * 0.1 : minY - 1;
        final chartMaxY = yDelta > 0 ? maxY + yDelta * 0.1 : maxY + 1;
        final yInterval = max(1.0, yDelta / 4);
        final xInterval = max(1.0, (spots.last.x - spots.first.x) / 6);

        return Scaffold(
          backgroundColor: const Color(0xFF091625),
          appBar: AppBar(
            backgroundColor: const Color(0xFF091625),
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Home()),
              ),
            ),
            title: const Text('S&P 500'),
          ),
          body: Card(
            color: const Color(0xFF091625),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'S&P 500 Index',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currentPrice != null
                                ? '\$${_formatPrice(_currentPrice!)}'
                                : 'N/A',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _change != null
                                ? '${_change! >= 0 ? '+' : ''}${_change!.toStringAsFixed(2)}'
                                : '',
                            style: TextStyle(
                              color: (_change ?? 0) >= 0
                                  ? Colors.green
                                  : Colors.red,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _percentChange != null
                                ? '${_percentChange!.toStringAsFixed(2)}%'
                                : '',
                            style: TextStyle(
                              color: (_percentChange ?? 0) >= 0
                                  ? Colors.green
                                  : Colors.red,
                              fontSize: 14,
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
                          padding: const EdgeInsets.symmetric(horizontal: 4),
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
                  if (_isRangeLoading)
                    const SizedBox(
                      height: 280,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    SizedBox(
                      height: 280,
                      width: double.infinity,
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
                                  final label = _xLabel(value, _selectedRange);
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
                                    '${value.toInt()}',
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
                              color: Colors.grey.withValues(alpha: 51),
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border.all(color: Colors.green, width: 1),
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
                                color: Colors.green.withValues(alpha: 64),
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
