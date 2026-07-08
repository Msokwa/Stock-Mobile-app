import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import '../home.dart';

enum ChartRange { week, month, year, twoYears }

class Chart1 extends StatefulWidget {
  final List<FlSpot>? data;
  const Chart1({super.key, this.data});

  @override
  State<Chart1> createState() => _ChartsState();
}

class _ChartsState extends State<Chart1> {
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
    // Load UI immediately; fetch data in background with staggered delay
    _loadFuture = Future.value();
    // Add delay to prevent rate limiting when multiple charts load simultaneously
    Future.delayed(const Duration(milliseconds: 500), _loadDAXData);
  }

  Future<void> _loadDAXData() async {
    _currentPrice = 16247.94;
    _change = 218.53;
    _percentChange = 1.36;
    await _loadRangeData(_selectedRange);
  }

  Future<void> _loadRangeData(ChartRange range) async {
    setState(() {
      _isRangeLoading = true;
      _rangeError = null;
    });
    setState(() {
      _spots = _dummySpots(range);
      _isRangeLoading = false;
    });
  }

  List<FlSpot> _defaultSpots() => const [
    FlSpot(0, 16020),
    FlSpot(1, 16110),
    FlSpot(2, 16185),
    FlSpot(3, 16247),
    FlSpot(4, 16302),
    FlSpot(5, 16280),
    FlSpot(6, 16420),
  ];

  List<FlSpot> _dummySpots(ChartRange range) {
    switch (range) {
      case ChartRange.week:
        return const [
          FlSpot(0, 16000),
          FlSpot(1, 16080),
          FlSpot(2, 16135),
          FlSpot(3, 16210),
          FlSpot(4, 16205),
          FlSpot(5, 16290),
          FlSpot(6, 16340),
        ];
      case ChartRange.month:
        return const [
          FlSpot(0, 15890),
          FlSpot(1, 15980),
          FlSpot(2, 16040),
          FlSpot(3, 16120),
          FlSpot(4, 16200),
          FlSpot(5, 16285),
          FlSpot(6, 16350),
          FlSpot(7, 16410),
        ];
      case ChartRange.year:
        return const [
          FlSpot(0, 15020),
          FlSpot(1, 15210),
          FlSpot(2, 15480),
          FlSpot(3, 15620),
          FlSpot(4, 15890),
          FlSpot(5, 16040),
          FlSpot(6, 16210),
          FlSpot(7, 16480),
        ];
      case ChartRange.twoYears:
        return const [
          FlSpot(0, 14200),
          FlSpot(1, 14610),
          FlSpot(2, 14980),
          FlSpot(3, 15340),
          FlSpot(4, 15690),
          FlSpot(5, 15920),
          FlSpot(6, 16240),
          FlSpot(7, 16510),
        ];
    }
  }

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
    final formatter = (price).toStringAsFixed(2);
    return formatter;
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
            title: const Text('DAX'),
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
                            'DAX ',
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
