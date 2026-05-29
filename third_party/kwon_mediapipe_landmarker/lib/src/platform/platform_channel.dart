import 'package:flutter/services.dart';

/// Platform Channel 정의
class PlatformChannel {
  PlatformChannel._();

  static const MethodChannel channel =
      MethodChannel('com.kwon.mediapipe_landmarker');

  static const EventChannel eventChannel =
      EventChannel('com.kwon.mediapipe_landmarker/stream');
}

/// 메서드 이름 상수
class MethodNames {
  MethodNames._();

  static const String initialize = 'initialize';
  static const String detect = 'detect';
  static const String startStream = 'startStream';
  static const String stopStream = 'stopStream';
  static const String dispose = 'dispose';
}

/// 파라미터 키 상수
class ParamKeys {
  ParamKeys._();

  // Initialize
  static const String enableFace = 'enableFace';
  static const String enablePose = 'enablePose';
  static const String faceNumFaces = 'faceNumFaces';
  static const String faceMinDetectionConfidence = 'faceMinDetectionConfidence';
  static const String faceMinTrackingConfidence = 'faceMinTrackingConfidence';
  static const String faceOutputBlendshapes = 'faceOutputBlendshapes';
  static const String faceOutputTransformationMatrix =
      'faceOutputTransformationMatrix';
  static const String poseNumPoses = 'poseNumPoses';
  static const String poseMinDetectionConfidence = 'poseMinDetectionConfidence';
  static const String poseMinTrackingConfidence = 'poseMinTrackingConfidence';

  // Detect
  static const String imageBytes = 'imageBytes';
  static const String imageWidth = 'imageWidth';
  static const String imageHeight = 'imageHeight';
  static const String imageRotation = 'imageRotation';
  static const String imageFormat = 'imageFormat';

  // Camera Stream (YUV planes)
  static const String planes = 'planes';
  static const String bytesPerRow = 'bytesPerRow';
}

/// 에러 코드 상수
class ErrorCodes {
  ErrorCodes._();

  static const String notInitialized = 'NOT_INITIALIZED';
  static const String initializationFailed = 'INITIALIZATION_FAILED';
  static const String modelLoadFailed = 'MODEL_LOAD_FAILED';
  static const String detectionFailed = 'DETECTION_FAILED';
  static const String invalidImage = 'INVALID_IMAGE';
  static const String platformNotSupported = 'PLATFORM_NOT_SUPPORTED';
}
