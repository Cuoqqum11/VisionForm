import 'package:kwon_mediapipe_landmarker/kwon_mediapipe_landmarker.dart' as kwon;

class FaultRecord {
  final int elapsedSeconds;
  final String workoutName;
  final int score;
  final List<kwon.Landmark> landmarks; //the skeleton data
  
  FaultRecord({
    required this.elapsedSeconds,
    required this.workoutName,
    required this.score,
    required this.landmarks,
  });

  //Convert to JSON for data storage
  Map<String, dynamic> toJson() {
    return {
      'elapsedSeconds': elapsedSeconds,
      'workoutName': workoutName,
      'score': score,
      'landmarks': landmarks.map((lm) => lm.toMap()).toList(),
    };
  }

  //read the data from JSON
  factory FaultRecord.fromJson(Map<String, dynamic> json) {
    return FaultRecord(
      elapsedSeconds: json['elapsedSeconds'] as int,
      workoutName: json['workoutName'] as String,
      score: json['score'] as int,
      landmarks: (json['landmarks'] as List)
          .map((lm) => kwon.Landmark.fromMap(lm as Map<String, dynamic>)).toList(),

    );
  }
}