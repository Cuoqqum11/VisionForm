/// Face Landmarker 설정
class FaceOptions {
  /// 최대 감지 얼굴 수 (기본값: 1)
  final int numFaces;

  /// 얼굴 감지 최소 신뢰도 (0.0~1.0, 기본값: 0.5)
  final double minDetectionConfidence;

  /// 얼굴 추적 최소 신뢰도 (0.0~1.0, 기본값: 0.5)
  final double minTrackingConfidence;

  /// 블렌드쉐입 출력 여부 (기본값: true)
  final bool outputBlendshapes;

  /// Transformation Matrix 출력 여부 (기본값: false)
  final bool outputTransformationMatrix;

  const FaceOptions({
    this.numFaces = 1,
    this.minDetectionConfidence = 0.5,
    this.minTrackingConfidence = 0.5,
    this.outputBlendshapes = true,
    this.outputTransformationMatrix = false,
  })  : assert(numFaces >= 1, 'numFaces must be at least 1'),
        assert(minDetectionConfidence >= 0.0 && minDetectionConfidence <= 1.0,
            'minDetectionConfidence must be between 0.0 and 1.0'),
        assert(minTrackingConfidence >= 0.0 && minTrackingConfidence <= 1.0,
            'minTrackingConfidence must be between 0.0 and 1.0');

  /// Map으로 변환 (Platform Channel용)
  Map<String, dynamic> toMap() {
    return {
      'numFaces': numFaces,
      'minDetectionConfidence': minDetectionConfidence,
      'minTrackingConfidence': minTrackingConfidence,
      'outputBlendshapes': outputBlendshapes,
      'outputTransformationMatrix': outputTransformationMatrix,
    };
  }

  /// 복사본 생성
  FaceOptions copyWith({
    int? numFaces,
    double? minDetectionConfidence,
    double? minTrackingConfidence,
    bool? outputBlendshapes,
    bool? outputTransformationMatrix,
  }) {
    return FaceOptions(
      numFaces: numFaces ?? this.numFaces,
      minDetectionConfidence:
          minDetectionConfidence ?? this.minDetectionConfidence,
      minTrackingConfidence:
          minTrackingConfidence ?? this.minTrackingConfidence,
      outputBlendshapes: outputBlendshapes ?? this.outputBlendshapes,
      outputTransformationMatrix:
          outputTransformationMatrix ?? this.outputTransformationMatrix,
    );
  }

  @override
  String toString() {
    return 'FaceOptions(numFaces: $numFaces, minDetectionConfidence: $minDetectionConfidence, '
        'minTrackingConfidence: $minTrackingConfidence, outputBlendshapes: $outputBlendshapes, '
        'outputTransformationMatrix: $outputTransformationMatrix)';
  }
}

/// Pose Landmarker 설정
class PoseOptions {
  /// 최대 감지 포즈 수 (기본값: 1)
  final int numPoses;

  /// 포즈 감지 최소 신뢰도 (0.0~1.0, 기본값: 0.5)
  final double minDetectionConfidence;

  /// 포즈 추적 최소 신뢰도 (0.0~1.0, 기본값: 0.5)
  final double minTrackingConfidence;

  const PoseOptions({
    this.numPoses = 1,
    this.minDetectionConfidence = 0.5,
    this.minTrackingConfidence = 0.5,
  })  : assert(numPoses >= 1, 'numPoses must be at least 1'),
        assert(minDetectionConfidence >= 0.0 && minDetectionConfidence <= 1.0,
            'minDetectionConfidence must be between 0.0 and 1.0'),
        assert(minTrackingConfidence >= 0.0 && minTrackingConfidence <= 1.0,
            'minTrackingConfidence must be between 0.0 and 1.0');

  /// Map으로 변환 (Platform Channel용)
  Map<String, dynamic> toMap() {
    return {
      'numPoses': numPoses,
      'minDetectionConfidence': minDetectionConfidence,
      'minTrackingConfidence': minTrackingConfidence,
    };
  }

  /// 복사본 생성
  PoseOptions copyWith({
    int? numPoses,
    double? minDetectionConfidence,
    double? minTrackingConfidence,
  }) {
    return PoseOptions(
      numPoses: numPoses ?? this.numPoses,
      minDetectionConfidence:
          minDetectionConfidence ?? this.minDetectionConfidence,
      minTrackingConfidence:
          minTrackingConfidence ?? this.minTrackingConfidence,
    );
  }

  @override
  String toString() {
    return 'PoseOptions(numPoses: $numPoses, minDetectionConfidence: $minDetectionConfidence, '
        'minTrackingConfidence: $minTrackingConfidence)';
  }
}
