import 'dart:async';

//files imports
import '../models/faultrecord.dart';
import '../models/workout_session_summary.dart';
import '../Logic/workout_logic.dart';
import 'workout_result_screen.dart';
import '../Logic/virtual_coach.dart';

//package imports
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:kwon_mediapipe_landmarker/kwon_mediapipe_landmarker.dart' as kwon;

class CameraTrackingUI extends StatefulWidget {
  const CameraTrackingUI({
    super.key,
    required this.workoutName,
    required this.instructions,
  });

  final String workoutName;
  final List<String> instructions;

  @override
  State<CameraTrackingUI> createState() => _CameraTrackingUIState();
}

class _CameraTrackingUIState extends State<CameraTrackingUI> {
  // Live Feedback Tracker
  String _liveFeedback = "Ready to start!";
  
  // Squat tracking
  bool _wasInSquatUpPosition = false;
  int _squatRepCount = 0;

  final List<FaultRecord> faultRecords = []; //to store the temporary fault records during the session
  int _lastFaultScore = 100; // MUST be here, outside of any functions!
  DateTime? _trackingStartTime; // We will need this to calculate your elapsed time
  
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isPermissionDenied = false;
  CameraLensDirection _currentLens = CameraLensDirection.back;

  bool _isMediaPipeReady = false;
  bool _isProcessingFrame = false;
  DateTime _lastProcess = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastUiUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  List<kwon.Landmark> _poseLandmarks = [];
  int _score = 0;

  bool _isTracking = false;
  bool _isGeneratingSummary = false; // To prevent multiple rapid taps on "Stop" causing issues
  Timer? _timer;
  int _elapsedSeconds = 0;
  DateTime? _trackingStartedAt;

  // Sit-up tracking
  bool _wasInSitupUpPosition = false;
  int _situpRepCount = 0;

  // Push-up tracking
  bool _wasInPushupUpPosition = false;
  int _pushupRepCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isPermissionDenied = false;
      _isCameraInitialized = false;
    });

    final status = await Permission.camera.request();
    if (!mounted) return;

    if (status.isDenied || status.isPermanentlyDenied) {
      setState(() => _isPermissionDenied = true);
      return;
    }

    try {
      final cameras = await availableCameras();
      if (!mounted) return;

      if (cameras.isEmpty) {
        setState(() {
          _isPermissionDenied = false;
          _isCameraInitialized = false;
        });
        return;
      }

      final camera = cameras.firstWhere(
        (c) => c.lensDirection == _currentLens,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await _cameraController!.initialize();

      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
        _isPermissionDenied = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = false;
        _isPermissionDenied = false;
      });
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _toggleTracking() async {
    if (_isTracking) {
      setState(() {
        _isTracking = false;
      });

      await _stopImageStream();
      if (!mounted) return;

      setState(() {
        _poseLandmarks = [];
        _timer?.cancel();
        _timer = null;
      });

      final summary = WorkoutSessionSummary(
        workoutName: widget.workoutName,
        elapsedSeconds: _elapsedSeconds,
        faultRecords: List<FaultRecord>.unmodifiable(faultRecords),
        repCount: _situpRepCount,
        finishedAt: DateTime.now(),
      );

      Provider.of<WorkoutProvide>(context, listen: false).setLatestWorkoutSummary(summary);

      if (!mounted) return;

      if (faultRecords.isNotEmpty) {
        debugPrint('Caught ${faultRecords.length} low-score frames for ${widget.workoutName}:');
        for (var record in faultRecords) {
          debugPrint('Time: ${record.elapsedMilliseconds}ms, Score: ${record.score}, Landmarks: ${record.landmarks.length}');
        }
      } else {
        debugPrint('Perfect set! No faults detected for ${widget.workoutName}.');
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => WorkoutResultScreen(summary: summary),
        ),
      );
      return;
    }

    setState(() {
      _isTracking = true;
      _elapsedSeconds = 0;
      _trackingStartedAt = DateTime.now();
      _wasInSitupUpPosition = false;
      _situpRepCount = 0;
      _wasInPushupUpPosition = false;
      _pushupRepCount = 0;
      faultRecords.clear();
    });

    await _ensureMediaPipeReady();
    _startImageStream();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _elapsedSeconds++);
    });
  }

  Future<void> _ensureMediaPipeReady() async {
    if (_isMediaPipeReady) return;
    try {
      if (kwon.KwonMediapipeLandmarker.isInitialized) {
        await kwon.KwonMediapipeLandmarker.dispose();
      }
      await kwon.KwonMediapipeLandmarker.initialize(face: false, pose: true);
      if (!mounted) return;
      setState(() => _isMediaPipeReady = true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isMediaPipeReady = false;
        _poseLandmarks = [];
      });
      debugPrint('MediaPipe init failed: $e');
    }
  }

  void _startImageStream() {
    if (_cameraController == null) return;
    try {
      _cameraController!.startImageStream(_onCameraFrame);
    } catch (e) {
      debugPrint('startImageStream failed: $e');
    }
  }

  Future<void> _stopImageStream() async {
    try {
      await _cameraController?.stopImageStream();
    } catch (_) {}
  }

  Future<void> _onCameraFrame(CameraImage image) async {
    if (!_isMediaPipeReady || _isProcessingFrame) return;
    if (DateTime.now().difference(_lastProcess).inMilliseconds < 120) return;
    _lastProcess = DateTime.now();
    _isProcessingFrame = true;

    try {
      final planes = image.planes.map((p) => p.bytes).toList();
      final bytesPerRow = image.planes.map((p) => p.bytesPerRow).toList();
      final format = image.format.group.name.toLowerCase();
      final rotation = _cameraController?.description.sensorOrientation ?? 0;

      final result = await kwon.KwonMediapipeLandmarker.detectFromCamera(
        planes: planes,
        width: image.width,
        height: image.height,
        rotation: rotation,
        format: format,
        bytesPerRow: bytesPerRow,
      );

      if (!mounted) return;
      final pose = result.pose;
      final landmarks = pose?.landmarks ?? [];
      final newScore = _computeScore(landmarks);
      final now = DateTime.now();

      if (newScore < 70 && _isTracking) {
        faultRecords.add(FaultRecord(
          elapsedSeconds: _elapsedSeconds,
          elapsedMilliseconds: _trackingStartedAt == null
              ? _elapsedSeconds * 1000
              : now.difference(_trackingStartedAt!).inMilliseconds,
          workoutName: widget.workoutName,
          score: newScore,
          landmarks: landmarks,
        ));
      }
      
      if (now.difference(_lastUiUpdate).inMilliseconds >= 140) {
        _lastUiUpdate = now;
        setState(() {
          _poseLandmarks = landmarks;
          _score = newScore;
        });
      }
    } catch (e) {
      debugPrint('MediaPipe detect failed: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  int _computeScore(List<kwon.Landmark> landmarks) {
    if (landmarks.isEmpty) return 0;
    
    // Calculate base visibility score
    final withVisibility = landmarks.where((lm) => lm.visibility != null).toList();
    int baseScore;
    if (withVisibility.isEmpty) {
      baseScore = (landmarks.length / 33.0 * 100).clamp(0, 100).round();
    } else {
      final avg = withVisibility
              .map((lm) => lm.visibility ?? 0)
              .fold<double>(0, (sum, v) => sum + v) /
          withVisibility.length;
      baseScore = (avg * 100).clamp(0, 100).round();
    }

    // Apply workout-specific penalties
    int finalScore = baseScore;

    // Squat form validation
 // Squat form validation & Rep Tracking
    if (widget.workoutName.toLowerCase() == 'squats') {
      try {
        final poseResult = kwon.PoseResult(
          landmarks: landmarks,
          worldLandmarks: [],
          segmentationMasks: [],
        );

        final isUp = poseResult.isSquatUpPosition;
        final isDown = poseResult.isSquatDownPosition;
        final alignment = poseResult.shoulderFeetAlignment;
        
        // Default feedback when moving
        String currentFeedback = "Keep going...";

        // 1. Rep Counting Logic
        if (isUp && !_wasInSquatUpPosition) {
          _wasInSquatUpPosition = true;
          _squatRepCount++;
          currentFeedback = "Good rep! $_squatRepCount completed.";
        } else if (isDown) {
          _wasInSquatUpPosition = false;
          currentFeedback = "Good depth, now push up!";
        }

        // 2. Form Validation (Live Correction)
        // If they lean too far forward (offset > 0.1), overwrite the feedback with a correction
        if (!poseResult.isSquatFormCorrect(offset: 0.1)) {
          final penalty = (alignment * 200).toInt();
          finalScore = (finalScore - penalty).clamp(0, 100);
          
          currentFeedback = "Keep your back straight and chest up!"; // Hard-coded live tip
        } 
        // If they stop halfway down, tell them to go lower
        else if (!isDown && !isUp && poseResult.squatKneeAngle < 140 && poseResult.squatKneeAngle >= 100) {
           currentFeedback = "Lower! Get your hips to knee level.";
        }

        // Update the UI string safely without causing infinite rebuild loops
        if (_liveFeedback != currentFeedback && _isTracking) {
          _liveFeedback = currentFeedback;
        }

      } catch (e) {
        debugPrint('Squat validation error: $e');
      }
    }

    // Push-up form validation
    if (widget.workoutName.toLowerCase() == 'push-ups' || widget.workoutName.toLowerCase() == 'push up') {
      try {
        final poseResult = kwon.PoseResult(
          landmarks: landmarks,
          worldLandmarks: [],
          segmentationMasks: [],
        );

        final armAngle = poseResult.pushupArmAngle;
        final isUp = poseResult.isPushupStartingPositionCorrect(angleTolerance: 20);
        final isDown = poseResult.isPushupBottomPositionCorrect(angleTolerance: 20);

        String currentFeedback = "Keep going...";
        // 1. Rep Counting Logic
        if (isUp && !_wasInPushupUpPosition) {
          _wasInPushupUpPosition = true;
          _pushupRepCount++;
          currentFeedback = "Good rep! Rep: $_pushupRepCount completed.";
        } else if (isDown) {
          _wasInPushupUpPosition = false;
          currentFeedback = "Push up!";
        }
        // 2. Form Validation (Live Correction)
        final bodyAngle = poseResult.pushupBodyAngle;
        final flareAngle = poseResult.pushupTorsoArmAngle;
        final isElbowFlareCorrect = poseResult.isPushupElbowFlareCorrect(targetAngle: 45, angleTolerance: 20);
        // 2.1. Check for body angle/straightness
        if (bodyAngle < 160) {
          final bodyPenalty = ((180 - bodyAngle) * 2).clamp(0, 30).toInt();
          finalScore = (finalScore - bodyPenalty).clamp(0, 100);
          currentFeedback = "Keep your body straight! Don't let your hips sag.";
        }
        // 2.2. Check for elbow flare
        else if (!isElbowFlareCorrect && armAngle < 150) {
          final flarePenalty = (((flareAngle - 45).abs() / 45) * 15).clamp(0, 15).toInt();
          finalScore = (finalScore - flarePenalty).clamp(0, 100);
          currentFeedback = "Tuck your elbows closer to your body!";
        }
        // 2.3. Check for arm angle
        else if (!isUp && !isDown) {
          final distanceFromIdeal = ((armAngle - 90).abs() - 90).abs();
          final depthPenalty = ((distanceFromIdeal / 90) * 20).clamp(0, 20).toInt();
          finalScore = (finalScore - depthPenalty).clamp(0, 100);
          
          if (armAngle > 100 && armAngle < 150) {
            currentFeedback = "Go lower!";
          }
        }

        // Update UI
        if (_liveFeedback != currentFeedback && _isTracking) {
          _liveFeedback = currentFeedback;
        }

      } catch (e) {
        debugPrint('Pushup validation error: $e');
      }
    }
    // Sit-up form validation & Rep Tracking
// Sit-up form validation & Rep Tracking
    if (widget.workoutName.toLowerCase() == 'sit up' || widget.workoutName.toLowerCase() == 'sit ups') {
      try {
        final poseResult = kwon.PoseResult(
          landmarks: landmarks,
          worldLandmarks: [],
          segmentationMasks: [],
        );

        final torsoAngle = poseResult.situpTorsoAngle;
        final isDown = poseResult.isSitupDownPosition;
        final isUp = poseResult.isSitupUpPosition;

        String currentFeedback = "Keep going...";

        // 1. Rep Counting Logic
        if (isUp && !_wasInSitupUpPosition) {
          _wasInSitupUpPosition = true;
          _situpRepCount++;
          currentFeedback = "Good rep! $_situpRepCount completed.";
        } else if (isDown) {
          _wasInSitupUpPosition = false;
          currentFeedback = "Engage core and sit up!";
        }

        // 2. Scoring Logic
        if (!isDown && !isUp) {
          final distanceFromMidpoint = (torsoAngle - 45).abs(); 
          final penalty = ((15 - distanceFromMidpoint) / 15 * 15).clamp(0, 15).toInt();
          finalScore = (finalScore - penalty).clamp(0, 100);
        }

        // Update UI
        if (_liveFeedback != currentFeedback && _isTracking) {
          _liveFeedback = currentFeedback;
        }

      } catch (e) {
        debugPrint('Sit-up validation error: $e');
      }
    }
    if (finalScore < 70 && _lastFaultScore >= 70) {
      
      // Calculate how long they have been working out
      final elapsedMs = _trackingStartTime != null 
          ? DateTime.now().difference(_trackingStartTime!).inMilliseconds 
          : 0;
      faultRecords.add(
        FaultRecord(
          elapsedSeconds: elapsedMs ~/ 1000,
          elapsedMilliseconds: elapsedMs,
          workoutName: widget.workoutName,
          score: finalScore,
          landmarks: landmarks, // Saving the exact skeleton frame
          feedbackMessage: _liveFeedback,
        ));
      debugPrint('Fault Recorded! Score: $finalScore at ${elapsedMs ~/ 1000} seconds');
    }

    // Update the tracker for the next frame
    _lastFaultScore = finalScore;
    
    return finalScore;
  }

  Future<void> _flipCamera() async {
    if (_isTracking) {
      _toggleTracking();
    }

    await _stopImageStream();
    await _cameraController?.dispose();
    _cameraController = null;

    setState(() {
      _currentLens = _currentLens == CameraLensDirection.back
          ? CameraLensDirection.front
          : CameraLensDirection.back;
      _isCameraInitialized = false;
    });

    await _initializeCamera();
  }

  String get _primaryInstruction {
    if (widget.instructions.isNotEmpty) {
      final trimmed = widget.instructions.where((step) => step.trim().isNotEmpty).toList();
      if (trimmed.isEmpty) {
        return 'Keep your full body in frame before starting.';
      }
      if (trimmed.length == 1) {
        return trimmed.first;
      }
      return '${trimmed[0]}\n${trimmed[1]}';
    }
    return 'Keep your full body in frame before starting.';
  }

  @override
  void dispose() {
    _stopImageStream();
    _cameraController?.dispose();
    _timer?.cancel();
    _timer = null;
    kwon.KwonMediapipeLandmarker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isPermissionDenied) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Camera access is required for tracking.', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => openAppSettings(),
                child: const Text('Open Settings'),
              ),
              TextButton(
                onPressed: _initializeCamera,
                child: const Text('Retry', style: TextStyle(color: Colors.orange)),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isCameraInitialized || _cameraController == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: CameraPreview(_cameraController!),
          ),

          if (_isTracking)
            Positioned.fill(
              child: CustomPaint(
                painter: _PoseOverlayPainter(
                  landmarks: _poseLandmarks,
                  mirror: _currentLens == CameraLensDirection.front,
                ),
              ),
            ),

          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.flip_camera_android, color: Colors.white, size: 28),
              onPressed: _flipCamera,
            ),
          ),

          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(153),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withAlpha(179)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _primaryInstruction,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),

                        if (_isTracking)...[
                          Text(
                            _liveFeedback,
                            style: TextStyle(
                              color: _score < 70 ? Colors.redAccent : Colors.greenAccent, 
                              fontSize: 16, 
                              fontWeight: FontWeight.bold
                            ), 
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          'Score: ${_isTracking ? _score : '--'}',
                          style: const TextStyle(color: Colors.orange, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_isTracking)
                  Text(
                    'Time: $_elapsedSeconds sec',
                    style: const TextStyle(color: Colors.orange, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isTracking ? Colors.red : Colors.orange,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  onPressed: () => _toggleTracking(),
                  child: Text(
                    _isTracking ? 'Stop Tracking' : 'Start Tracking',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PoseOverlayPainter extends CustomPainter {
  _PoseOverlayPainter({required this.landmarks, required this.mirror});

  final List<kwon.Landmark> landmarks;
  final bool mirror;

  @override
  void paint(Canvas canvas, Size size) {
    if (landmarks.isEmpty) return;

    final paint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.fill;

    for (final lm in landmarks) {
      final x = mirror ? (1.0 - lm.x) : lm.x;
      final offset = Offset(x * size.width, lm.y * size.height);
      canvas.drawCircle(offset, 4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PoseOverlayPainter oldDelegate) {
    return oldDelegate.landmarks != landmarks || oldDelegate.mirror != mirror;
  }
}
