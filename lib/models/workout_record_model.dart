
class WorkoutRecord {
  final int id;
  final int workoutId;
  final DateTime date;
  final int timeStamp;
  final int duration;
  final int reps;
  final int sets;
  final String notes;

  WorkoutRecord({
    required this.id,
    required this.workoutId,
    required this.date,
    required this.timeStamp,
    required this.duration,
    required this.reps,
    required this.sets,
    required this.notes,
  });

  Map<String, dynamic> toMap(){
    return <String, dynamic>{
      'id': id,
      'workoutId': workoutId,
      'date': date.toIso8601String(),
      'timeStamp': timeStamp,
      'duration': duration,
      'reps': reps,
      'sets': sets,
      'notes': notes,
    };
  }

  factory WorkoutRecord.fromMap(Map<String, dynamic> map){
    return WorkoutRecord(
      id: map['id'] as int,
      workoutId: map['workoutId'] as int,
      date: DateTime.parse(map['date'] as String),
      timeStamp: map['timeStamp'] as int,
      duration: map['duration'] as int,
      reps: map['reps'] as int,
      sets: map['sets'] as int,
      notes: map['notes'] as String,
    );
  }


}