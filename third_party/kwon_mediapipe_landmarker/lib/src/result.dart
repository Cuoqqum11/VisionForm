import 'landmark.dart';

/// 전체 분석 결과
class LandmarkerResult {
  /// 얼굴 분석 결과 (face=true일 때)
  final FaceResult? face;

  /// 자세 분석 결과 (pose=true일 때)
  final PoseResult? pose;

  /// 분석 시점 타임스탬프 (밀리초)
  final int timestampMs;

  const LandmarkerResult({
    this.face,
    this.pose,
    required this.timestampMs,
  });

  /// Map에서 LandmarkerResult 생성
  factory LandmarkerResult.fromMap(Map<String, dynamic> map) {
    return LandmarkerResult(
      face: map['face'] != null
          ? FaceResult.fromMap(_convertMap(map['face']))
          : null,
      pose: map['pose'] != null
          ? PoseResult.fromMap(_convertMap(map['pose']))
          : null,
      timestampMs: (map['timestampMs'] as num).toInt(),
    );
  }

  /// 결과가 비어있는지 확인
  bool get isEmpty => face == null && pose == null;

  /// 결과가 있는지 확인
  bool get isNotEmpty => !isEmpty;

  /// 얼굴이 감지되었는지 확인
  bool get hasFace => face != null && face!.landmarks.isNotEmpty;

  /// 포즈가 감지되었는지 확인
  bool get hasPose => pose != null && pose!.landmarks.isNotEmpty;

  @override
  String toString() {
    return 'LandmarkerResult(face: ${face != null ? 'detected' : 'null'}, '
        'pose: ${pose != null ? 'detected' : 'null'}, timestampMs: $timestampMs)';
  }
}

/// 얼굴 분석 결과
class FaceResult {
  /// 478개 얼굴 랜드마크 좌표
  final List<Landmark> landmarks;

  /// 52개 블렌드쉐입 (표정 계수)
  /// key: 블렌드쉐입 이름, value: 0.0~1.0 강도
  final Map<String, double> blendshapes;

  /// 얼굴 변환 행렬 (4x4, 선택적)
  final List<double>? transformationMatrix;

  const FaceResult({
    required this.landmarks,
    required this.blendshapes,
    this.transformationMatrix,
  });

  /// Map에서 FaceResult 생성
  factory FaceResult.fromMap(Map<String, dynamic> map) {
    // landmarks 파싱
    final landmarksData = map['landmarks'] as List<dynamic>? ?? [];
    final landmarks = landmarksData
        .map((e) => Landmark.fromMap(_convertMap(e)))
        .toList();

    // blendshapes 파싱
    final blendshapesRaw = map['blendshapes'];
    final blendshapes = <String, double>{};
    if (blendshapesRaw != null) {
      final blendshapesData = _convertMap(blendshapesRaw);
      blendshapesData.forEach((key, value) {
        blendshapes[key.toString()] = (value as num).toDouble();
      });
    }

    // transformationMatrix 파싱
    List<double>? transformationMatrix;
    if (map['transformationMatrix'] != null) {
      final matrixData = map['transformationMatrix'] as List<dynamic>;
      transformationMatrix =
          matrixData.map((e) => (e as num).toDouble()).toList();
    }

    return FaceResult(
      landmarks: landmarks,
      blendshapes: blendshapes,
      transformationMatrix: transformationMatrix,
    );
  }

  /// 특정 인덱스의 랜드마크 가져오기
  Landmark? getLandmark(int index) {
    if (index < 0 || index >= landmarks.length) return null;
    return landmarks[index];
  }

  /// 특정 블렌드쉐입 값 가져오기
  double getBlendshape(String name) {
    return blendshapes[name] ?? 0.0;
  }

  // === 편의 속성들 (표정 분석) ===

  /// 미소 점수 (0.0~1.0)
  double get smileScore {
    final mouthSmileLeft = blendshapes['mouthSmileLeft'] ?? 0.0;
    final mouthSmileRight = blendshapes['mouthSmileRight'] ?? 0.0;
    return (mouthSmileLeft + mouthSmileRight) / 2.0;
  }

  /// 눈썹 올림 점수 (0.0~1.0)
  double get browRaiseScore {
    final browInnerUp = blendshapes['browInnerUp'] ?? 0.0;
    final browOuterUpLeft = blendshapes['browOuterUpLeft'] ?? 0.0;
    final browOuterUpRight = blendshapes['browOuterUpRight'] ?? 0.0;
    return (browInnerUp + browOuterUpLeft + browOuterUpRight) / 3.0;
  }

  /// 눈 깜빡임 (왼쪽)
  double get eyeBlinkLeft => blendshapes['eyeBlinkLeft'] ?? 0.0;

  /// 눈 깜빡임 (오른쪽)
  double get eyeBlinkRight => blendshapes['eyeBlinkRight'] ?? 0.0;

  /// 눈 시선 분석 - 아이컨택 점수 (간단 버전)
  double get eyeContactScore {
    final eyeLookOutLeft = blendshapes['eyeLookOutLeft'] ?? 0.0;
    final eyeLookOutRight = blendshapes['eyeLookOutRight'] ?? 0.0;
    final eyeLookInLeft = blendshapes['eyeLookInLeft'] ?? 0.0;
    final eyeLookInRight = blendshapes['eyeLookInRight'] ?? 0.0;
    final eyeLookUpLeft = blendshapes['eyeLookUpLeft'] ?? 0.0;
    final eyeLookUpRight = blendshapes['eyeLookUpRight'] ?? 0.0;
    final eyeLookDownLeft = blendshapes['eyeLookDownLeft'] ?? 0.0;
    final eyeLookDownRight = blendshapes['eyeLookDownRight'] ?? 0.0;

    // 시선이 정면을 향할수록 점수가 높음
    final avgLookAway = (eyeLookOutLeft +
            eyeLookOutRight +
            eyeLookInLeft +
            eyeLookInRight +
            eyeLookUpLeft +
            eyeLookUpRight +
            eyeLookDownLeft +
            eyeLookDownRight) /
        8.0;

    return 1.0 - avgLookAway.clamp(0.0, 1.0);
  }

  @override
  String toString() {
    return 'FaceResult(landmarks: ${landmarks.length}, '
        'blendshapes: ${blendshapes.length}, '
        'hasTransformationMatrix: ${transformationMatrix != null})';
  }
}

/// 자세 분석 결과
class PoseResult {
  /// 33개 몸 랜드마크 좌표
  final List<Landmark> landmarks;

  /// 33개 월드 좌표 (미터 단위)
  final List<Landmark>? worldLandmarks;

  const PoseResult({
    required this.landmarks,
    this.worldLandmarks,
  });

  /// Map에서 PoseResult 생성
  factory PoseResult.fromMap(Map<String, dynamic> map) {
    // landmarks 파싱
    final landmarksData = map['landmarks'] as List<dynamic>? ?? [];
    final landmarks = landmarksData
        .map((e) => Landmark.fromMap(_convertMap(e)))
        .toList();

    // worldLandmarks 파싱
    List<Landmark>? worldLandmarks;
    if (map['worldLandmarks'] != null) {
      final worldData = map['worldLandmarks'] as List<dynamic>;
      worldLandmarks = worldData
          .map((e) => Landmark.fromMap(_convertMap(e)))
          .toList();
    }

    return PoseResult(
      landmarks: landmarks,
      worldLandmarks: worldLandmarks,
    );
  }

  /// 특정 인덱스의 랜드마크 가져오기
  Landmark? getLandmark(int index) {
    if (index < 0 || index >= landmarks.length) return null;
    return landmarks[index];
  }

  /// 특정 인덱스의 월드 랜드마크 가져오기
  Landmark? getWorldLandmark(int index) {
    if (worldLandmarks == null ||
        index < 0 ||
        index >= worldLandmarks!.length) {
      return null;
    }
    return worldLandmarks![index];
  }

  @override
  String toString() {
    return 'PoseResult(landmarks: ${landmarks.length}, '
        'worldLandmarks: ${worldLandmarks?.length ?? 0})';
  }
}

/// 재귀적으로 Map을 `Map<String, dynamic>`으로 변환
Map<String, dynamic> _convertMap(dynamic data) {
  if (data is Map<String, dynamic>) {
    return data;
  }
  if (data is Map) {
    return Map<String, dynamic>.from(data);
  }
  throw ArgumentError('Expected Map but got ${data.runtimeType}');
}
