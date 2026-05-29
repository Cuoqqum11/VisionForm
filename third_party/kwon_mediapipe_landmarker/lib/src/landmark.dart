/// 랜드마크 좌표
class Landmark {
  /// 랜드마크 인덱스 (0-based)
  final int index;

  /// 정규화된 X 좌표 (0.0~1.0, 이미지 왼쪽=0)
  final double x;

  /// 정규화된 Y 좌표 (0.0~1.0, 이미지 위=0)
  final double y;

  /// 정규화된 Z 좌표 (깊이, 상대값)
  final double z;

  /// 가시성 (0.0~1.0, 해당 부위가 보이는 정도)
  /// Face는 null, Pose만 있음
  final double? visibility;

  /// 존재 확률 (0.0~1.0, 해당 부위가 프레임에 있는 확률)
  /// Face는 null, Pose만 있음
  final double? presence;

  const Landmark({
    required this.index,
    required this.x,
    required this.y,
    required this.z,
    this.visibility,
    this.presence,
  });

  /// Map에서 Landmark 생성
  factory Landmark.fromMap(Map<String, dynamic> map) {
    return Landmark(
      index: map['index'] as int,
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
      z: (map['z'] as num).toDouble(),
      visibility: map['visibility'] != null
          ? (map['visibility'] as num).toDouble()
          : null,
      presence:
          map['presence'] != null ? (map['presence'] as num).toDouble() : null,
    );
  }

  /// Landmark를 Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'index': index,
      'x': x,
      'y': y,
      'z': z,
      if (visibility != null) 'visibility': visibility,
      if (presence != null) 'presence': presence,
    };
  }

  @override
  String toString() {
    return 'Landmark(index: $index, x: ${x.toStringAsFixed(3)}, y: ${y.toStringAsFixed(3)}, z: ${z.toStringAsFixed(3)}'
        '${visibility != null ? ', visibility: ${visibility!.toStringAsFixed(3)}' : ''}'
        '${presence != null ? ', presence: ${presence!.toStringAsFixed(3)}' : ''})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Landmark &&
        other.index == index &&
        other.x == x &&
        other.y == y &&
        other.z == z &&
        other.visibility == visibility &&
        other.presence == presence;
  }

  @override
  int get hashCode {
    return Object.hash(index, x, y, z, visibility, presence);
  }
}
