import 'dart:math';
import 'package:flutter/material.dart';
import 'package:stock_app/services/historical_data_service.dart';

class CandlestickScreen extends StatefulWidget {
  final String symbol;

  const CandlestickScreen({super.key, required this.symbol});

  @override
  State<CandlestickScreen> createState() => _CandlestickScreenState();
}

class _CandlestickScreenState extends State<CandlestickScreen> {
  late Future<List<HistoricalDataPoint>> _future;
  int? _selectedIndex;
  double _zoom = 1.0; // 1.0 = full range, >1 zoomed in
  double _startIndexOffset = 0.0; // fractional start index for panning
  // Factor to bias horizontal vs vertical movement when deciding gesture intent.
  // Larger values make horizontal pans require proportionally more horizontal
  // movement compared to vertical movement. 1.2 is a reasonable default.
  final double _panVsSelectThreshold = 1.2;

  @override
  void initState() {
    super.initState();
    _future = HistoricalDataService.fetchOneYearData(widget.symbol);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF091625),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF191625),
        title: Text('${widget.symbol} Candlestick'),
      ),
      body: FutureBuilder<List<HistoricalDataPoint>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final data = snapshot.data ?? [];
          if (data.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.show_chart, size: 48, color: Colors.white70),
                  const SizedBox(height: 12),
                  const Text(
                    'No Marketstack candle data is available right now.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _future = HistoricalDataService.fetchOneYearData(
                          widget.symbol,
                        );
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        onTapDown: (details) {
                          final local = details.localPosition;
                          final size = constraints.biggest;
                          final idx = _indexForPosition(
                            local.dx,
                            size,
                            data.length,
                          );
                          setState(() => _selectedIndex = idx);
                        },
                        onScaleStart: (_) {},
                        onScaleUpdate: (details) {
                          final size = constraints.biggest;
                          if (details.scale != 1.0) {
                            final oldZoom = _zoom;
                            _zoom = (_zoom * details.scale).clamp(1.0, 8.0);
                            final focalLocal = details.localFocalPoint;
                            final focalIndex = _indexForPosition(
                              focalLocal.dx,
                              size,
                              data.length,
                            );
                            if (focalIndex != null) {
                              final visibleCountBefore = _visibleCount(
                                data.length,
                                oldZoom,
                              );
                              final visibleCountAfter = _visibleCount(
                                data.length,
                                _zoom,
                              );
                              final relative =
                                  (focalIndex - _startIndexOffset) /
                                  visibleCountBefore;
                              _startIndexOffset =
                                  (focalIndex - relative * visibleCountAfter)
                                      .clamp(
                                        0.0,
                                        (data.length - visibleCountAfter)
                                            .toDouble(),
                                      );
                            }
                            setState(() {});
                            return;
                          }

                          final dx = details.focalPointDelta.dx;
                          final dy = details.focalPointDelta.dy;

                          if (dx.abs() > dy.abs() * _panVsSelectThreshold &&
                              dx != 0) {
                            _panBy(dx, size, data.length);
                            return;
                          }

                          if (dy.abs() >= dx.abs() * _panVsSelectThreshold) {
                            final local = details.localFocalPoint;
                            final idx = _indexForPosition(
                              local.dx,
                              size,
                              data.length,
                            );
                            setState(() => _selectedIndex = idx);
                            return;
                          }
                        },
                        child: SizedBox.expand(
                          child: CustomPaint(
                            painter: _CandlestickPainter(
                              data,
                              selectedIndex: _selectedIndex,
                              zoom: _zoom,
                              startIndexOffset: _startIndexOffset,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text('${data.length} data points'),
              ],
            ),
          );
        },
      ),
    );
  }

  int? _indexForPosition(double dx, Size size, int count) {
    const double leftPad = 48.0;
    const double pad = 8.0;
    final innerW = size.width - leftPad - pad * 2;
    if (innerW <= 0) return null;
    final visibleCount = _visibleCount(count, _zoom);
    final barWidth = innerW / visibleCount;
    final x = dx - leftPad - pad;
    final idxF = x / barWidth + _startIndexOffset;
    int idx = idxF.floor();
    if (idx < 0) idx = 0;
    if (idx >= count) idx = count - 1;
    return idx;
  }

  void _panBy(double deltaDx, Size size, int count) {
    const double leftPad = 48.0;
    const double pad = 8.0;
    final innerW = size.width - leftPad - pad * 2;
    if (innerW <= 0) return;
    final visibleCount = _visibleCount(count, _zoom);
    final barWidth = innerW / visibleCount;
    // convert delta pixels to index offset (reverse direction)
    final deltaIndex = -deltaDx / barWidth;
    final maxStart = (count - visibleCount).toDouble().clamp(
      0.0,
      count.toDouble(),
    );
    _startIndexOffset = (_startIndexOffset + deltaIndex).clamp(0.0, maxStart);
    setState(() {});
  }

  int _visibleCount(int total, double zoom) {
    // zoom=1 => show full range, higher zoom shows fewer points
    final v = (total / zoom).round();
    return v.clamp(8, total);
  }
}

class _CandlestickPainter extends CustomPainter {
  final List<HistoricalDataPoint> data;
  final int? selectedIndex;
  final double zoom;
  final double startIndexOffset;
  _CandlestickPainter(
    this.data, {
    this.selectedIndex,
    this.zoom = 1.0,
    this.startIndexOffset = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = 1.0;
    const double leftPad = 48.0;
    const double pad = 8.0;
    final innerW = size.width - leftPad - pad * 2;
    final innerH = size.height - pad * 2 - 24; // leave space for date labels

    // determine price range for visible window
    final visibleCount = (data.length / zoom).round().clamp(8, data.length);
    final startIndex = startIndexOffset.floor().clamp(
      0,
      data.length - visibleCount,
    );
    double minP = data[startIndex].low;
    double maxP = data[startIndex].high;
    for (int j = startIndex; j < startIndex + visibleCount; j++) {
      final dd = data[j];
      if (dd.low < minP) minP = dd.low;
      if (dd.high > maxP) maxP = dd.high;
    }

    final priceRange = maxP - minP;
    if (priceRange <= 0) return;

    final barWidth = innerW / visibleCount;

    for (int i = 0; i < visibleCount; i++) {
      final dataIndex = startIndex + i;
      final d = data[dataIndex];
      final cx = leftPad + pad + i * barWidth + barWidth / 2;
      double mapY(double price) =>
          pad + innerH - ((price - minP) / priceRange) * innerH;

      final yHigh = mapY(d.high);
      final yLow = mapY(d.low);
      final yOpen = mapY(d.open);
      final yClose = mapY(d.close);

      // wick
      paint.color = Colors.white70;
      canvas.drawLine(Offset(cx, yHigh), Offset(cx, yLow), paint);

      // body
      final bodyLeft = cx - barWidth * 0.22;
      final bodyRight = cx + barWidth * 0.22;
      final top = min(yOpen, yClose);
      final bottom = max(yOpen, yClose);
      paint.style = PaintingStyle.fill;
      paint.color = d.close >= d.open ? Colors.green : Colors.red;
      final rect = Rect.fromLTRB(bodyLeft, top, bodyRight, bottom);
      canvas.drawRect(rect, paint);
      // highlight if selected
      if (selectedIndex != null && dataIndex == selectedIndex) {
        final hl = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = Colors.yellowAccent;
        canvas.drawRect(rect.inflate(2.0), hl);
      }
    }

    // draw Y axis labels (4 ticks)
    final tp = TextPainter(textDirection: TextDirection.ltr);
    const ticks = 4;
    for (int t = 0; t <= ticks; t++) {
      final v = minP + priceRange * (t / ticks);
      final y = pad + innerH - ((v - minP) / priceRange) * innerH;
      tp.text = TextSpan(
        text: v.toStringAsFixed(2),
        style: const TextStyle(color: Colors.white70, fontSize: 10),
      );
      tp.layout();
      tp.paint(canvas, Offset(4, y - tp.height / 2));
      // optional grid line
      final g = Paint()..color = Colors.white12;
      canvas.drawLine(Offset(leftPad + pad, y), Offset(size.width - pad, y), g);
    }

    // draw bottom date labels every N points
    final dateTp = TextPainter(textDirection: TextDirection.ltr);
    final step = (visibleCount / 6).ceil().clamp(1, visibleCount);
    for (int i = 0; i < visibleCount; i += step) {
      final dataIndex = startIndex + i;
      final d = data[dataIndex];
      final cx = leftPad + pad + i * barWidth + barWidth / 2;
      final label = '${d.timestamp.month}/${d.timestamp.day}';
      dateTp.text = TextSpan(
        text: label,
        style: const TextStyle(color: Colors.white70, fontSize: 10),
      );
      dateTp.layout();
      dateTp.paint(
        canvas,
        Offset(cx - dateTp.width / 2, size.height - pad - dateTp.height),
      );
    }

    // draw tooltip for selected index
    if (selectedIndex != null &&
        selectedIndex! >= 0 &&
        selectedIndex! < data.length) {
      final d = data[selectedIndex!];
      final tooltip =
          'O:${d.open.toStringAsFixed(2)} H:${d.high.toStringAsFixed(2)}\nL:${d.low.toStringAsFixed(2)} C:${d.close.toStringAsFixed(2)}';
      final tooltipTp = TextPainter(textDirection: TextDirection.ltr);
      tooltipTp.text = TextSpan(
        text: tooltip,
        style: const TextStyle(color: Colors.black, fontSize: 12),
      );
      tooltipTp.layout(maxWidth: size.width * 0.5);
      final tooltipW = tooltipTp.width + 12;
      final tooltipH = tooltipTp.height + 12;
      // place tooltip near right but avoid covering chart
      final dx = size.width - tooltipW - pad;
      final dy = pad;
      final bg = RRect.fromLTRBR(
        dx,
        dy,
        dx + tooltipW,
        dy + tooltipH,
        const Radius.circular(6),
      );
      final bgPaint = Paint()..color = Colors.white70;
      canvas.drawRRect(bg, bgPaint);
      tooltipTp.paint(canvas, Offset(dx + 6, dy + 6));
    }
  }

  @override
  bool shouldRepaint(covariant _CandlestickPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.zoom != zoom ||
        oldDelegate.startIndexOffset != startIndexOffset;
  }
}
