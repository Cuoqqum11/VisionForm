import 'faultrecord.dart';

class WorkoutSessionSummary {
  static const int lowScoreSampleIntervalMs = 120;

  final String workoutName;
  final int elapsedSeconds;
  final List<FaultRecord> faultRecords;
  final int repCount;
  final DateTime finishedAt;

  const WorkoutSessionSummary({
    required this.workoutName,
    required this.elapsedSeconds,
    required this.faultRecords,
    required this.repCount,
    required this.finishedAt,
  });

  int get faultCount => faultRecords.length;

  double? get averageFaultScore {
    if (faultRecords.isEmpty) {
      return null;
    }

    final total = faultRecords.fold<int>(0, (sum, record) => sum + record.score);
    return total / faultRecords.length;
  }

  int? get lowestFaultScore {
    if (faultRecords.isEmpty) {
      return null;
    }

    return faultRecords
        .map((record) => record.score)
        .reduce((lowest, score) => score < lowest ? score : lowest);
  }

  double get timeUnderThresholdSeconds =>
      faultRecords.length * lowScoreSampleIntervalMs / 1000.0;

  bool get hasFaults => faultRecords.isNotEmpty;
}