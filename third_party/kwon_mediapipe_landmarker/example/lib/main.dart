import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:kwon_mediapipe_landmarker/kwon_mediapipe_landmarker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediaPipe Landmarker Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const CameraPage(),
    );
  }
}

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isCameraReady = false;
  bool _isMediaPipeReady = false;
  bool _isDetecting = false;
  bool _isDisposed = false;
  
  // 비동기 처리
  bool _isProcessingFrame = false;
  
  // 감지 모드
  bool _faceEnabled = true;
  bool _poseEnabled = true;  // Pose도 활성화
  
  // Results
  LandmarkerResult? _lastResult;
  int _frameCount = 0;
  int _processedFrames = 0;
  int _detectedFrames = 0;
  
  // FPS 계산
  DateTime? _lastFpsUpdate;
  double _fps = 0;
  int _fpsFrameCount = 0;
  
  // Debug
  final List<String> _debugLogs = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAll();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _addLog('AppLifecycleState: $state');
    
    if (state == AppLifecycleState.inactive || 
        state == AppLifecycleState.paused) {
      _pauseCamera();
    }
    else if (state == AppLifecycleState.resumed) {
      _resumeCamera();
    }
    else if (state == AppLifecycleState.detached) {
      _cleanupAll();
    }
  }

  void _pauseCamera() {
    if (_isDisposed) return;
    
    _addLog('Pausing camera...');
    _isDetecting = false;
    _isProcessingFrame = true;
    _isCameraReady = false;
    
    final controller = _cameraController;
    _cameraController = null;
    
    if (controller != null) {
      try {
        if (controller.value.isStreamingImages) {
          controller.stopImageStream().catchError((_) {});
        }
      } catch (_) {}
      
      Future.microtask(() {
        try {
          controller.dispose();
          _addLog('Camera controller disposed');
        } catch (e) {
          _addLog('Camera dispose error: $e');
        }
      });
    }
    
    if (mounted) setState(() {});
  }

  void _resumeCamera() {
    if (_isDisposed) return;
    if (_isCameraReady) return;
    
    _addLog('Resuming camera...');
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_isDisposed && mounted) {
        _isProcessingFrame = false;
        _initializeCamera();
      }
    });
  }

  void _cleanupAll() {
    if (_isDisposed) return;
    _isDisposed = true;
    _isDetecting = false;
    _isProcessingFrame = true;
    _isCameraReady = false;
    
    final controller = _cameraController;
    _cameraController = null;
    
    if (controller != null) {
      try {
        controller.stopImageStream().catchError((_) {});
      } catch (_) {}
      try {
        controller.dispose();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanupAll();
    KwonMediapipeLandmarker.dispose();
    super.dispose();
  }

  void _addLog(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    debugPrint('[DEBUG] $message');
    if (mounted && !_isDisposed) {
      setState(() {
        _debugLogs.insert(0, '[$timestamp] $message');
        if (_debugLogs.length > 50) {
          _debugLogs.removeLast();
        }
      });
    }
  }

  /// Handle LandmarkerException with appropriate error messages
  void _handleLandmarkerError(LandmarkerException e) {
    switch (e.error) {
      case LandmarkerError.notInitialized:
        _addLog('ERROR: Landmarker not initialized');
        break;
      case LandmarkerError.modelLoadFailed:
        _addLog('ERROR: Model load failed - check if model files exist');
        break;
      case LandmarkerError.invalidImage:
        _addLog('ERROR: Invalid image format');
        break;
      case LandmarkerError.detectionFailed:
        _addLog('ERROR: Detection failed');
        break;
      case LandmarkerError.cameraPermissionDenied:
        _addLog('ERROR: Camera permission denied');
        break;
      case LandmarkerError.initializationFailed:
        _addLog('ERROR: Initialization failed - ${e.message}');
        break;
      default:
        _addLog('ERROR: ${e.code} - ${e.message}');
    }
  }

  Future<void> _initializeAll() async {
    _addLog('Starting initialization...');
    
    // 1. Camera permission
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      _addLog('ERROR: Camera permission denied');
      return;
    }
    _addLog('Camera permission granted');
    
    // 2. Initialize camera
    await _initializeCamera();
    if (!_isCameraReady) return;
    
    // 3. Initialize MediaPipe (Face + Pose)
    if (!_isMediaPipeReady) {
      _addLog('Initializing MediaPipe (Face: $_faceEnabled, Pose: $_poseEnabled)...');
      try {
        await KwonMediapipeLandmarker.initialize(
          face: _faceEnabled,
          pose: _poseEnabled,
          faceOptions: const FaceOptions(
            numFaces: 1,
            minDetectionConfidence: 0.5,
            minTrackingConfidence: 0.5,
            outputBlendshapes: true,
            outputTransformationMatrix: false,
          ),
          poseOptions: const PoseOptions(
            numPoses: 1,
            minDetectionConfidence: 0.5,
            minTrackingConfidence: 0.5,
          ),
        );
        _isMediaPipeReady = true;
        _addLog('MediaPipe initialized: true');
      } on LandmarkerException catch (e) {
        _handleLandmarkerError(e);
        return;
      } catch (e) {
        _addLog('ERROR: Unexpected error: $e');
        return;
      }
    }
    
    _addLog('All initialization complete!');
  }

  Future<void> _initializeCamera() async {
    if (_isDisposed) return;
    
    _addLog('Initializing camera...');
    
    if (_cameraController != null) {
      try {
        await _cameraController!.dispose();
      } catch (_) {}
      _cameraController = null;
    }
    
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      _addLog('ERROR: No cameras available');
      return;
    }
    _addLog('Found ${cameras.length} cameras');
    
    final frontCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    _addLog('Using camera: ${frontCamera.name}, direction: ${frontCamera.lensDirection}');
    
    final controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    
    try {
      await controller.initialize();
      
      if (_isDisposed) {
        controller.dispose();
        return;
      }
      
      _cameraController = controller;
      _isCameraReady = true;
      
      _addLog('Camera initialized successfully');
      _addLog('Preview size: ${controller.value.previewSize}');
      
      if (mounted) setState(() {});
    } catch (e) {
      _addLog('ERROR: Camera init failed: $e');
      try {
        controller.dispose();
      } catch (_) {}
      _cameraController = null;
      _isCameraReady = false;
    }
  }

  void _startDetection() {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      _addLog('ERROR: Camera not ready');
      return;
    }
    
    _addLog('Starting detection (Face: $_faceEnabled, Pose: $_poseEnabled)...');
    _frameCount = 0;
    _processedFrames = 0;
    _detectedFrames = 0;
    _isProcessingFrame = false;
    _lastFpsUpdate = DateTime.now();
    _fpsFrameCount = 0;
    
    controller.startImageStream(_onCameraFrame);
    
    setState(() {
      _isDetecting = true;
    });
  }

  void _stopDetection() {
    _addLog('Stopping detection...');
    _cameraController?.stopImageStream();
    setState(() {
      _isDetecting = false;
      _isProcessingFrame = false;
    });
  }

  void _onCameraFrame(CameraImage image) {
    if (_isDisposed || !mounted) return;
    
    _frameCount++;
    
    if (_isProcessingFrame) {
      return;
    }
    
    _isProcessingFrame = true;
    
    _processFrame(image).then((_) {
      if (!_isDisposed) _isProcessingFrame = false;
    }).catchError((e) {
      if (!_isDisposed) {
        _isProcessingFrame = false;
        _addLog('Detection error: $e');
      }
    });
  }

  Future<void> _processFrame(CameraImage image) async {
    if (_isDisposed || !mounted) return;
    
    final controller = _cameraController;
    if (controller == null) return;
    
    _processedFrames++;
    
    // 30프레임마다 로그
    if (_processedFrames % 30 == 1) {
      _addLog('Processing frame #$_processedFrames');
    }
    
    try {
      final result = await KwonMediapipeLandmarker.detectFromCamera(
        planes: image.planes.map((p) => p.bytes).toList(),
        width: image.width,
        height: image.height,
        rotation: controller.description.sensorOrientation,
        format: 'YUV420',
        bytesPerRow: image.planes.map((p) => p.bytesPerRow).toList(),
      );
      
      if (_isDisposed || !mounted) return;
      
      if (result != null && (result.hasFace || result.hasPose)) {
        _detectedFrames++;
        
        // 30프레임마다 로그
        if (_detectedFrames % 30 == 1) {
          if (result.hasFace) {
            _addLog('Face DETECTED! Landmarks: ${result.face!.landmarks.length}');
          }
          if (result.hasPose) {
            _addLog('Pose DETECTED! Landmarks: ${result.pose!.landmarks.length}');
          }
        }
        
        // FPS 계산
        _fpsFrameCount++;
        final now = DateTime.now();
        final elapsed = now.difference(_lastFpsUpdate!).inMilliseconds;
        if (elapsed >= 1000) {
          _fps = _fpsFrameCount * 1000 / elapsed;
          _fpsFrameCount = 0;
          _lastFpsUpdate = now;
        }
        
        // UI 업데이트
        _lastResult = result;
        if (_detectedFrames % 3 == 0 && mounted && !_isDisposed) {
          setState(() {});
        }
      }
    } on LandmarkerException catch (e) {
      if (_processedFrames % 30 == 1 && !_isDisposed) {
        _handleLandmarkerError(e);
      }
    } catch (e) {
      if (_processedFrames % 30 == 1 && !_isDisposed) {
        _addLog('Detection error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MediaPipe Landmarker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Face 토글
          IconButton(
            icon: Icon(
              Icons.face,
              color: _faceEnabled ? Colors.blue : Colors.grey,
            ),
            onPressed: _isDetecting ? null : () {
              setState(() {
                _faceEnabled = !_faceEnabled;
              });
            },
            tooltip: 'Face Detection',
          ),
          // Pose 토글
          IconButton(
            icon: Icon(
              Icons.accessibility,
              color: _poseEnabled ? Colors.green : Colors.grey,
            ),
            onPressed: _isDetecting ? null : () {
              setState(() {
                _poseEnabled = !_poseEnabled;
              });
            },
            tooltip: 'Pose Detection',
          ),
        ],
      ),
      body: Column(
        children: [
          // Camera preview
          Expanded(
            flex: 2,
            child: _buildCameraPreview(),
          ),
          
          // Results
          Expanded(
            flex: 1,
            child: _buildResults(),
          ),
          
          // Debug logs
          Expanded(
            flex: 1,
            child: _buildDebugLogs(),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildCameraPreview() {
    if (!_isCameraReady) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('카메라 준비 중...'),
          ],
        ),
      );
    }
    
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('카메라 초기화 중...'),
          ],
        ),
      );
    }
    
    return Container(
      color: Colors.black,
      child: Center(
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.previewSize!.height,
                height: controller.value.previewSize!.width,
                child: CameraPreview(controller),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.grey[200],
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detection Results',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text('Frames: $_frameCount | Processed: $_processedFrames | Detected: $_detectedFrames'),
            Text('FPS: ${_fps.toStringAsFixed(1)} | Skip: ${_frameCount > 0 ? (100 * (_frameCount - _processedFrames) / _frameCount).toStringAsFixed(1) : 0}%'),
            
            // Face 결과
            if (_lastResult?.face != null) ...[
              const Divider(),
              Text('🙂 Face: ${_lastResult!.face!.landmarks.length} landmarks, ${_lastResult!.face!.blendshapes.length} blendshapes'),
              Text('   Smile: ${(_lastResult!.face!.smileScore * 100).toInt()}% | Eye Contact: ${(_lastResult!.face!.eyeContactScore * 100).toInt()}%'),
            ],
            
            // Pose 결과
            if (_lastResult?.pose != null) ...[
              const Divider(),
              Text('🏃 Pose: ${_lastResult!.pose!.landmarks.length} landmarks'),
              _buildPoseInfo(_lastResult!.pose!),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildPoseInfo(PoseResult pose) {
    // 수동으로 계산 (패키지 extension 대신)
    double shoulderSymmetry = 0.0;
    bool tensed = false;
    bool leftHandVisible = false;
    bool rightHandVisible = false;
    double avgDist = 0.0;

    if (pose.landmarks.length >= 13) {
      final leftY = pose.landmarks[11].y;  // leftShoulder
      final rightY = pose.landmarks[12].y; // rightShoulder
      final yDiff = (leftY - rightY).abs();
      shoulderSymmetry = (1.0 - yDiff * 5).clamp(0.0, 1.0);
    }

    if (pose.landmarks.length >= 13) {
      final leftEarY = pose.landmarks[7].y;
      final leftShoulderY = pose.landmarks[11].y;
      final rightEarY = pose.landmarks[8].y;
      final rightShoulderY = pose.landmarks[12].y;
      // 절대값 사용 (iOS/Android 좌표계 차이 대응)
      avgDist = ((leftShoulderY - leftEarY).abs() + (rightShoulderY - rightEarY).abs()) / 2;
      tensed = avgDist < 0.1;

      // Debug: 30프레임마다 좌표 로그 출력
      if (_detectedFrames % 30 == 1) {
        debugPrint('[POSE DEBUG] leftEar.y=${leftEarY.toStringAsFixed(3)}, leftShoulder.y=${leftShoulderY.toStringAsFixed(3)}');
        debugPrint('[POSE DEBUG] rightEar.y=${rightEarY.toStringAsFixed(3)}, rightShoulder.y=${rightShoulderY.toStringAsFixed(3)}');
        debugPrint('[POSE DEBUG] avgDist=${avgDist.toStringAsFixed(3)}, tensed=$tensed');
      }
    }

    if (pose.landmarks.length >= 16) {
      leftHandVisible = (pose.landmarks[15].visibility ?? 0) > 0.5;
    }
    if (pose.landmarks.length >= 17) {
      rightHandVisible = (pose.landmarks[16].visibility ?? 0) > 0.5;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('   Shoulder Symmetry: ${(shoulderSymmetry * 100).toInt()}%'),
        Text('   Tensed: ${tensed ? "Yes" : "No"} (dist: ${avgDist.toStringAsFixed(2)}) | Hands: L=${leftHandVisible ? "✓" : "✗"} R=${rightHandVisible ? "✓" : "✗"}'),
      ],
    );
  }

  Widget _buildDebugLogs() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.black87,
      child: ListView.builder(
        itemCount: _debugLogs.length,
        itemBuilder: (context, index) {
          return Text(
            _debugLogs[index],
            style: const TextStyle(
              color: Colors.greenAccent,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          );
        },
      ),
    );
  }

  Widget _buildFAB() {
    if (!_isCameraReady || !_isMediaPipeReady) {
      return const SizedBox.shrink();
    }
    
    return FloatingActionButton.extended(
      onPressed: _isDetecting ? _stopDetection : _startDetection,
      icon: Icon(_isDetecting ? Icons.stop : Icons.play_arrow),
      label: Text(_isDetecting ? 'Stop' : 'Start'),
      backgroundColor: _isDetecting ? Colors.red : Colors.green,
    );
  }
}
