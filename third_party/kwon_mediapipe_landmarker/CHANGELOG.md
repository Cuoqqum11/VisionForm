# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.3] - 2026-02-02

### Fixed
- Fixed LICENSE file to use exact Apache 2.0 template with APPENDIX section for pub.dev recognition

## [0.0.2] - 2026-02-02

### Fixed
- Fixed LICENSE file format for pub.dev OSI-approved license recognition (Apache 2.0)
- Fixed dartdoc angle brackets warning in `result.dart` (HTML interpretation issue)

## [0.0.1] - 2026-01-31

### Added
- **Face Landmarker** support
  - 478 facial landmarks detection
  - 52 ARKit-compatible blendshapes
  - Optional 4x4 transformation matrix output
- **Pose Landmarker** support
  - 33 body pose landmarks
  - World landmarks (meter units)
  - Visibility and presence scores
- **Real-time camera analysis**
  - Optimized YUV-to-RGB conversion (Android: parallel processing, iOS: vImage)
  - VIDEO mode for tracking optimization
- **Helper extensions**
  - FaceResultHelper: 14 methods (eyeContactScore, smileScore, tensionScore, etc.)
  - PoseResultHelper: 19 methods (postureScore, shoulderSymmetryScore, etc.)
- **Structured error handling**
  - LandmarkerError enum with 11 error codes
  - LandmarkerException class with detailed error information
- **Platform support**
  - Android (minSdk 24, MediaPipe Tasks Vision)
  - iOS (iOS 12.0+, MediaPipe Tasks Vision)
- **iOS front camera mirroring correction**
  - X coordinate inversion
  - Left/Right landmark index swap for accurate detection
- Example app with Face + Pose simultaneous detection
