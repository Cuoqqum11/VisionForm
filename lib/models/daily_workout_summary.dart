class DailyWorkoutSummary {
  final DateTime date;
  final double averageScore; // Represents 0.0 to 100.0%
  final int totalReps;       // Total reps across all workouts that day

  DailyWorkoutSummary({
    required this.date,
    required this.averageScore,
    required this.totalReps,
  });
}