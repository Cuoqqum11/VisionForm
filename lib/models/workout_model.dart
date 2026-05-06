import 'dart:convert';
class Workout {
  final int? id;
  final String name;
  final int duration;
  final String description;
  final List<String> instruction;
  final String imageUrl;
  
  Workout({
    this.id,
    required this.name,
    required this.duration,
    required this.description,
    required this.instruction,
    required this.imageUrl,
  });
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'duration': duration,
      'description': description,
      'instruction': jsonEncode(instruction),
      'imageUrl': imageUrl,
    };
  }
  factory Workout.fromMap(Map<String, dynamic> map) {
    return Workout(
      id: map['id'] as int?,
      name: map['name'] as String,
      duration: map['duration'] as int,
      description: map['description'] as String,
      instruction: List<String>.from(jsonDecode(map['instruction'] as String)),
      imageUrl: map['imageUrl'] as String,
    );
  }
}