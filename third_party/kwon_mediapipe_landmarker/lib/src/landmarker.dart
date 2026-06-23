import 'dart:async';

import 'package:flutter/services.dart';

import 'exceptions.dart';
import 'options.dart';
import 'result.dart';
import 'platform/platform_channel.dart';

/// MediaPipe Face + Pose Landmarker 통합 래퍼
///
/// 영어 면접/프레젠테이션 연습 앱에서 표정, 시선, 자세 실시간 분석에 사용
///
/// ```dart
/// // 초기화
/// await KwonMediapipeLandmarker.initialize(
///   face: true,
///   pose: true,
/// );
///
/// // 이미지 분석
/// final result = await KwonMediapipeLandmarker.detect(imageBytes);
///
/// // 해제
/// await KwonMediapipeLandmarker.dispose();
/// ```
class KwonMediapipeLandmarker {
  KwonMediapipeLandmarker._();

  static bool _isInitialized = false;
  static bool _faceEnabled = false;
  static bool _poseEnabled = false;
  static StreamSubscription<dynamic>? _streamSubscription;
  static StreamController<LandmarkerResult>? _resultStreamController;

  /// 초기화 상태 확인
  static bool get isInitialized => _isInitialized;

  /// Face Landmarker 활성화 여부
  static bool get isFaceEnabled => _faceEnabled;

  /// Pose Landmarker 활성화 여부
  static bool get isPoseEnabled => _poseEnabled;

  /// 초기화 (모델 로드)
  ///
  /// [face] - Face Landmarker 활성화 여부 (기본값: true)
  /// [pose] - Pose Landmarker 활성화 여부 (기본값: false)
  /// [faceOptions] - Face Landmarker 설정
  /// [poseOptions] - Pose Landmarker 설정
  ///
  /// ```dart
  /// await KwonMediapipeLandmarker.initialize(
  ///   face: true,
  ///   pose: true,
  ///   faceOptions: FaceOptions(
  ///     numFaces: 1,
  ///     outputBlendshapes: true,
  ///   ),
  /// );
  /// ```
  static Future<void> initialize({
    bool face = true,
    bool pose = false,
    FaceOptions? faceOptions,
    PoseOptions? poseOptions,
  }) async {
    if (_isInitialized) {
      throw const LandmarkerException(
        error: LandmarkerError.initializationFailed,
        message: 'KwonMediapipeLandmarker is already initialized. '
            'Call dispose() first before reinitializing.',
      );
    }

    if (!face && !pose) {
      throw const LandmarkerException(
        error: LandmarkerError.invalidArguments,
        message: 'At least one of face or pose must be enabled.',
      );
    }

    final effectiveFaceOptions = faceOptions ?? const FaceOptions();
    final effectivePoseOptions = poseOptions ?? const PoseOptions();

    try {
      await PlatformChannel.channel.invokeMethod(
        MethodNames.initialize,
        {
          ParamKeys.enableFace: face,
          ParamKeys.enablePose: pose,
          ParamKeys.faceNumFaces: effectiveFaceOptions.numFaces,
          ParamKeys.faceMinDetectionConfidence:
              effectiveFaceOptions.minDetectionConfidence,
          ParamKeys.faceMinTrackingConfidence:
              effectiveFaceOptions.minTrackingConfidence,
          ParamKeys.faceOutputBlendshapes:
              effectiveFaceOptions.outputBlendshapes,
          ParamKeys.faceOutputTransformationMatrix:
              effectiveFaceOptions.outputTransformationMatrix,
          ParamKeys.poseNumPoses: effectivePoseOptions.numPoses,
          ParamKeys.poseMinDetectionConfidence:
              effectivePoseOptions.minDetectionConfidence,
          ParamKeys.poseMinTrackingConfidence:
              effectivePoseOptions.minTrackingConfidence,
        },
      );

      _isInitialized = true;
      _faceEnabled = face;
      _poseEnabled = pose;
    } on PlatformException catch (e) {
      throw LandmarkerException.fromCode(
        e.code,
        'Failed to initialize landmarker: ${e.message}',
        originalError: e,
      );
    }
  }

  /// 단일 이미지 분석 (이미지 바이트)
  ///
  /// [imageBytes] - JPEG, PNG 등 이미지 바이트
  ///
  /// ```dart
  /// final imageBytes = await file.readAsBytes();
  /// final result = await KwonMediapipeLandmarker.detect(imageBytes);
  ///
  /// if (result.hasFace) {
  ///   print('시선 점수: ${result.face!.eyeContactScore}');
  /// }
  /// ```
  static Future<LandmarkerResult> detect(Uint8List imageBytes) async {
    _checkInitialized();

    try {
      final result = await PlatformChannel.channel.invokeMethod<Map>(
        MethodNames.detect,
        {
          ParamKeys.imageBytes: imageBytes,
        },
      );

      if (result == null) {
        return LandmarkerResult(
          timestampMs: DateTime.now().millisecondsSinceEpoch,
        );
      }

      return LandmarkerResult.fromMap(Map<String, dynamic>.from(result));
    } on PlatformException catch (e) {
      throw LandmarkerException.fromCode(
        e.code,
        'Detection failed: ${e.message}',
        originalError: e,
      );
    }
  }

  /// 카메라 프레임 분석 (camera 패키지의 CameraImage 형식)
  ///
  /// [planes] - YUV 이미지 plane 데이터
  /// [width] - 이미지 너비
  /// [height] - 이미지 높이
  /// [rotation] - 이미지 회전 (0, 90, 180, 270)
  /// [format] - 이미지 포맷 (예: 'yuv420', 'nv21', 'bgra8888')
  ///
  /// ```dart
  /// final result = await KwonMediapipeLandmarker.detectFromCamera(
  ///   planes: image.planes.map((p) => p.bytes).toList(),
  ///   width: image.width,
  ///   height: image.height,
  ///   rotation: camera.sensorOrientation,
  ///   format: image.format.group.name,
  /// );
  /// ```
  static Future<LandmarkerResult> detectFromCamera({
    required List<Uint8List> planes,
    required int width,
    required int height,
    required int rotation,
    required String format,
    List<int>? bytesPerRow,
  }) async {
    _checkInitialized();

    try {
      final result = await PlatformChannel.channel.invokeMethod<Map>(
        MethodNames.detect,
        {
          ParamKeys.planes: planes,
          ParamKeys.imageWidth: width,
          ParamKeys.imageHeight: height,
          ParamKeys.imageRotation: rotation,
          ParamKeys.imageFormat: format,
          if (bytesPerRow != null) ParamKeys.bytesPerRow: bytesPerRow,
        },
      );

      if (result == null) {
        return LandmarkerResult(
          timestampMs: DateTime.now().millisecondsSinceEpoch,
        );
      }

      return LandmarkerResult.fromMap(Map<String, dynamic>.from(result));
    } on PlatformException catch (e) {
      throw LandmarkerException.fromCode(
        e.code,
        'Camera detection failed: ${e.message}',
        originalError: e,
      );
    }
  }

  /// 카메라 프레임 스트림 분석 시작
  ///
  /// EventChannel을 통해 네이티브에서 직접 결과를 받음
  ///
  /// ```dart
  /// final stream = KwonMediapipeLandmarker.startStream();
  /// stream.listen((result) {
  ///   setState(() => _lastResult = result);
  /// });
  /// ```
  static Stream<LandmarkerResult> startStream() {
    _checkInitialized();

    // 기존 스트림이 있으면 정리
    _cleanupStream();

    _resultStreamController = StreamController<LandmarkerResult>.broadcast();

    _streamSubscription = PlatformChannel.eventChannel
        .receiveBroadcastStream()
        .listen(
      (dynamic event) {
        if (event is Map) {
          final result = LandmarkerResult.fromMap(
            Map<String, dynamic>.from(event),
          );
          _resultStreamController?.add(result);
        }
      },
      onError: (dynamic error) {
        _resultStreamController?.addError(
          LandmarkerException(
            error: LandmarkerError.detectionFailed,
            message: 'Stream error: $error',
            originalError: error,
          ),
        );
      },
    );

    // 네이티브에 스트림 시작 알림
    PlatformChannel.channel.invokeMethod(MethodNames.startStream);

    return _resultStreamController!.stream;
  }

  /// 카메라 프레임 스트림 분석 중지
  static Future<void> stopStream() async {
    _cleanupStream();
    await PlatformChannel.channel.invokeMethod(MethodNames.stopStream);
  }

  /// 리소스 해제
  ///
  /// 앱 종료 또는 더 이상 사용하지 않을 때 호출
  ///
  /// ```dart
  /// @override
  /// void dispose() {
  ///   KwonMediapipeLandmarker.dispose();
  ///   super.dispose();
  /// }
  /// ```
  static Future<void> dispose() async {
    _cleanupStream();

    if (_isInitialized) {
      try {
        await PlatformChannel.channel.invokeMethod(MethodNames.dispose);
      } catch (_) {
        // 이미 해제된 경우 무시
      }
    }

    _isInitialized = false;
    _faceEnabled = false;
    _poseEnabled = false;
  }

  /// 초기화 상태 확인
  static void _checkInitialized() {
    if (!_isInitialized) {
      throw const LandmarkerException(
        error: LandmarkerError.notInitialized,
        message: 'KwonMediapipeLandmarker is not initialized. '
            'Call initialize() first.',
      );
    }
  }

  /// 스트림 정리
  static void _cleanupStream() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _resultStreamController?.close();
    _resultStreamController = null;
  }
}
