import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/daily_workout_summary.dart';
import '../Logic/chart_mock_data.dart';
import '../database/database_helper.dart';

class YearlyProgressChart extends StatefulWidget {
  const YearlyProgressChart({super.key});

  @override
  State<YearlyProgressChart> createState() => _YearlyProgressChartState();
}

class _YearlyProgressChartState extends State<YearlyProgressChart> {
  List<DailyWorkoutSummary> _data = [];
  double _maxReps = 1.0; 
  bool _isLoading = true;

  @override
  Future<void> _loadRealData() async {
    // Call our new Singleton database helper
    final dbHelper = DatabaseHelper();
    final realData = await dbHelper.getYearlyChartData();

    double tempMax = 1.0;
    for (var day in realData) {
      if (day.totalReps > tempMax) {
        tempMax = day.totalReps.toDouble();
      }
    }

    // Update the UI with the real SQLite data!
    if (mounted) {
      setState(() {
        _data = realData;
        _maxReps = tempMax;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. DYNAMIC SCREEN CALCULATIONS
    // Get the absolute physical width of the user's device screen
    final deviceWidth = MediaQuery.of(context).size.width;
    
    // Account for the padding around the chart container (left: 8, right: 16)
    // plus any page margins so our math is pixel-perfect.
    final availableWidth = deviceWidth - 48; 

    // Dynamically calculate how wide one day needs to be so exactly 
    // 30 days fit inside the viewport window.
    final dayWidth = availableWidth / 30; 
    
    // Total width of the canvas is now perfectly scaled to the device!
    final chartWidth = _data.length * dayWidth;

    return Container(
      height: 380,
      padding: const EdgeInsets.only(top: 45, bottom: 12, left: 8, right: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1F25), 
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 16.0, bottom: 24.0),
            child: Text(
              'Monthly Progress',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              // This automatically scrolls the chart to the very end (today) 
              // when it loads, so the user sees their most recent data first!
              reverse: true, 
              child: SizedBox(
                width: chartWidth, 
                child: LineChart(
                  _mainChartData(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _mainChartData() {
    return LineChartData(
      minY: 0,
      maxY: 100,
      minX: 0,
      maxX: _data.length.toDouble() - 1,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 25,
        getDrawingHorizontalLine: (value) => FlLine(color: Colors.white10, strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        show: true,
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 30, // Shows a month indicator roughly every 30 days
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= _data.length || value.toInt() < 0) return const SizedBox.shrink();
              final date = _data[value.toInt()].date;
              
              // Only show the label on the first day of the month to keep the bottom clean
              if (date.day == 1 || value == 0) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    DateFormat('MMM').format(date), 
                    style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 25,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              return Text('${value.toInt()}%', style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold));
            },
          ),
        ),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 25,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              final actualReps = (value * (_maxReps / 100)).round();
              if (value == 0) return const SizedBox.shrink();
              return Text('$actualReps', style: const TextStyle(color: Colors.cyan, fontSize: 11, fontWeight: FontWeight.bold));
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineTouchData: LineTouchData(
        // Makes the touch area larger so it's easier to tap with a thumb
        touchSpotThreshold: 20, 
        touchTooltipData: LineTouchTooltipData(
          // THE MAGIC FIXES: Force the tooltip to stay inside the box!
          fitInsideHorizontally: true,
          fitInsideVertically: true, 
          
          // UI Polish: Make the box look sleek and stay close to the line
          tooltipMargin: 8, 
          tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          
          getTooltipItems: (touchedSpots) {
            if (touchedSpots.isEmpty) return [];
            
            final dayIndex = touchedSpots.first.x.toInt();
            final date = _data[dayIndex].date;
            final dateStr = DateFormat('MMM d, yyyy').format(date);
            
            return touchedSpots.map((spot) {
              if (spot.barIndex == 0) {
                return LineTooltipItem(
                  '$dateStr\nScore: ${spot.y.toStringAsFixed(1)}%',
                  const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13),
                );
              } else {
                final actualReps = (spot.y * (_maxReps / 100)).round();
                return LineTooltipItem(
                  'Reps: $actualReps',
                  const TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold, fontSize: 13),
                );
              }
            }).toList();
          },
        ),
      ),
      lineBarsData: [
        // Accuracy Line (Orange)
        LineChartBarData(
          spots: _data.asMap().entries.map((entry) {
            return FlSpot(entry.key.toDouble(), entry.value.averageScore);
          }).toList(),
          isCurved: true,
          color: Colors.orange,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.orange.withOpacity(0.05),
          ),
        ),
        // Reps Line (Cyan)
        LineChartBarData(
          spots: _data.asMap().entries.map((entry) {
            double scaledReps = (entry.value.totalReps / _maxReps) * 100;
            return FlSpot(entry.key.toDouble(), scaledReps);
          }).toList(),
          isCurved: true,
          color: Colors.cyan,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
        ),
      ],
    );
  }
}