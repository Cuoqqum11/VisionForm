import 'package:kwon_mediapipe_landmarker/kwon_mediapipe_landmarker.dart' as kwon;

class FaultRecord {
  final int elapsedSeconds;
  final int elapsedMilliseconds;
  final String workoutName;
  final int score;
  final List<kwon.Landmark> landmarks; //the skeleton data
  
  FaultRecord({
    required this.elapsedSeconds,
    required this.elapsedMilliseconds,
    required this.workoutName,
    required this.score,
    required this.landmarks,
  });

  //Convert to JSON for data storage
  Map<String, dynamic> toJson() {
    return {
      'elapsedSeconds': elapsedSeconds,
      'elapsedMilliseconds': elapsedMilliseconds,
      'workoutName': workoutName,
      'score': score,
      'landmarks': landmarks.map((lm) => lm.toMap()).toList(),
    };
  }

  //read the data from JSON
  factory FaultRecord.fromJson(Map<String, dynamic> json) {
    return FaultRecord(
      elapsedSeconds: json['elapsedSeconds'] as int,
      elapsedMilliseconds: json['elapsedMilliseconds'] as int? ?? (json['elapsedSeconds'] as int) * 1000,
      workoutName: json['workoutName'] as String,
      score: json['score'] as int,
      landmarks: (json['landmarks'] as List)
          .map((lm) => kwon.Landmark.fromMap(lm as Map<String, dynamic>)).toList(),

    );
  }
}