import 'dart:math';
import '../models/daily_workout_summary.dart';

class ChartMockData {
static List<DailyWorkoutSummary> generateYearOfData() {
    final List<DailyWorkoutSummary> mockData = [];
    final random = Random();
    
    final today = DateTime.now();
    // Force the generator to start exactly on your testing date!
    // Using 2025 since we are currently in 2026.
    final startDate = DateTime(2025, 7, 10); 
    
    // Calculate exactly how many days have passed since July 10th
    final daysToGenerate = today.difference(startDate).inDays;

    double baseReps = 20.0;

    // Change the loop to only run for the days that have actually passed
    for (int i = 0; i <= daysToGenerate; i++) {
      final currentDate = startDate.add(Duration(days: i));
      
      bool isRestDay = random.nextDouble() > 0.75;
      
      if (isRestDay) {
        mockData.add(DailyWorkoutSummary(
          date: currentDate, 
          averageScore: 0, 
          totalReps: 0
        ));
      } else {
        baseReps += random.nextDouble() * 0.5; 
        int dailyReps = (baseReps + random.nextInt(15) - 5).round();
        double dailyScore = 80.0 + random.nextInt(18) + random.nextDouble();
        if (random.nextDouble() > 0.9) dailyScore -= 15.0; 

        mockData.add(DailyWorkoutSummary(
          date: currentDate,
          averageScore: dailyScore,
          totalReps: dailyReps > 0 ? dailyReps : 0, 
        ));
      }
    }
    return mockData;
  }
}