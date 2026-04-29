import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraTrackingUI extends StatefulWidget {
  const CameraTrackingUI({super.key});

  @override
  State<CameraTrackingUI> createState() => _CameraTrackingUIState();
}

class _CameraTrackingUIState extends State<CameraTrackingUI> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isPermissionDenied = false;

  bool _isTracking = false;
  Timer? _timer;
  int _elapsedSeconds = 0;
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
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(camera, ResolutionPreset.high);
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

  void _toggleTracking() {
    setState(() {
      _isTracking = !_isTracking;

      if (_isTracking) {
        _elapsedSeconds = 0;
        _timer?.cancel();
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) {
            timer.cancel();
            return;
          }
          setState(() => _elapsedSeconds++);
        });
      } else {
        _timer?.cancel();
        _timer = null;
      }
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // IF PERMISSION IS DENIED: Show the "Open Settings" screen
    if (_isPermissionDenied) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Camera access is required for tracking.", style: TextStyle(color: Colors.white)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => openAppSettings(), // Opens the phone's settings
                child: const Text("Open Settings"),
              ),
              TextButton(
                onPressed: _initializeCamera,
                child: const Text("Retry", style: TextStyle(color: Colors.orange)),
              ),
            ],
          ),
        ),
      );
    }

    // IF STILL LOADING: Show a spinner
    if (!_isCameraInitialized || _cameraController == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    // THE MAIN CAMERA SCREEN
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // The live video feed
          Positioned.fill(
            child: CameraPreview(_cameraController!),
          ),
          
          // The back button
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // The Bottom Control Bar (Timer and Button)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Timer Text
                if (_isTracking)
                  Text(
                    "Time: $_elapsedSeconds sec",
                    style: const TextStyle(color: Colors.orange, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                const SizedBox(height: 10),
                
                // Start/Stop Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isTracking ? Colors.red : Colors.orange,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  onPressed: _toggleTracking,
                  child: Text(
                    _isTracking ? "Stop Tracking" : "Start Tracking",
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
