import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/daily_workout_summary.dart';
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
  void initState() {
    super.initState();
    _loadRealData();
  }
  
  Future<void> _loadRealData() async {
    final dbHelper = DatabaseHelper();
    final realData = await dbHelper.getYearlyChartData();

    double tempMax = 1.0;
    for (var day in realData) {
      if (day.totalReps > tempMax) {
        tempMax = day.totalReps.toDouble();
      }
    }

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
    if (_isLoading) {
      return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator(color: Colors.orange)));
    }

    return Container(
      height: 300,
      width: double.infinity, // Ensures it doesn't overflow
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1F25),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Monthly Progress', 
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(_mainChartData()),
          ),
        ],
      ),
    );
  }

  LineChartData _mainChartData() {
    return LineChartData(
      minY: 0,
      maxY: 100,
      maxX: _data.isEmpty ? 1 : (_data.length - 1).toDouble(),
      gridData: FlGridData(
        show: true, 
        drawVerticalLine: false, 
        horizontalInterval: 50,
        getDrawingHorizontalLine: (value) => FlLine(color: Colors.white10, strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true, 
            interval: 50, 
            reservedSize: 30,
            getTitlesWidget: (value, meta) => Text('${value.toInt()}%', 
              style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: _data.length > 30 ? 30 : 10,
            getTitlesWidget: (value, meta) {
              if (_data.isEmpty) return const SizedBox.shrink();
              final index = value.toInt();
              if (index >= 0 && index < _data.length) {
                return Text(DateFormat('MMM').format(_data[index].date), 
                  style: const TextStyle(color: Colors.white38, fontSize: 10));
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
      lineBarsData: [
        // Accuracy Line (Orange)
        LineChartBarData(
          spots: _data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.averageScore)).toList(),
          isCurved: true,
          color: Colors.orange,
          barWidth: 3,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: true, color: Colors.orange.withOpacity(0.1)),
        ),
        // Repetitions Line (Cyan)
        LineChartBarData(
          spots: _data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value.totalReps / _maxReps) * 100)).toList(),
          isCurved: true,
          color: Colors.cyan,
          barWidth: 3,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: true, color: Colors.cyan.withOpacity(0.1)),
        ),
      ],
    );
  }
}