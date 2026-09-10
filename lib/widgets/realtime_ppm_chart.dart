import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class RealtimePpmChart extends StatefulWidget {
  final int currentPpm;
  final int threshold;

  const RealtimePpmChart({
    super.key,
    required this.currentPpm,
    required this.threshold,
  });

  @override
  State<RealtimePpmChart> createState() => _RealtimePpmChartState();
}

class _RealtimePpmChartState extends State<RealtimePpmChart> {
  final List<FlSpot> _ppmSpots = [];
  int _timeIndex = 0;
  final int _maxDataPoints = 10;

  @override
  void initState() {
    super.initState();
    _addPoint(widget.currentPpm);
  }

  @override
  void didUpdateWidget(covariant RealtimePpmChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.currentPpm != widget.currentPpm || _ppmSpots.isEmpty) {
      _addPoint(widget.currentPpm);
    }
  }

  void _addPoint(int ppm) {
    setState(() {
      _timeIndex++;

      _ppmSpots.add(
        FlSpot(
          _timeIndex.toDouble(),
          ppm.toDouble(),
        ),
      );

      if (_ppmSpots.length > _maxDataPoints) {
        _ppmSpots.removeAt(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Real-Time PPM Trend Chart',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: false,
                  ),
                  titlesData: const FlTitlesData(
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Colors.grey.shade300,
                    ),
                  ),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: widget.threshold.toDouble(),
                        color: Colors.red,
                        strokeWidth: 2,
                        dashArray: [5, 5],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          labelResolver: (line) =>
                              'Limit (${widget.threshold})',
                        ),
                      ),
                    ],
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _ppmSpots,
                      isCurved: true,
                      color: widget.currentPpm >= widget.threshold
                          ? Colors.red
                          : Colors.indigo,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: (
                          widget.currentPpm >= widget.threshold
                              ? Colors.red
                              : Colors.indigo
                        ).withOpacity(0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}