# kwon_mediapipe_landmarker

[![pub package](https://img.shields.io/pub/v/kwon_mediapipe_landmarker.svg)](https://pub.dev/packages/kwon_mediapipe_landmarker)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-green.svg)](https://flutter.dev)

A Flutter plugin for real-time face and pose landmark detection using MediaPipe. Designed for interview practice apps, presentation coaching, and any application requiring facial expression, eye contact, and posture analysis.

## Features

- **Face Landmarker**: 478 facial landmarks with 52 ARKit-compatible blendshapes
- **Pose Landmarker**: 33 body pose landmarks with visibility and world coordinates
- **Real-time Camera Analysis**: Optimized native YUV-to-RGB conversion for smooth performance
- **Rich Helper Extensions**: 14 face analysis methods + 19 pose analysis methods
- **Simultaneous Detection**: Run face and pose detection together

## Performance

### Android (Samsung SM-S938N, Snapdragon 8 Gen 3)

| Mode | YUV Conversion | Detection | Total | FPS |
|------|----------------|-----------|-------|-----|
| Face Only | 6-9ms | 35-45ms | 41-54ms | ~20 FPS |
| Face + Pose | 7-13ms | 41-68ms | 52-80ms | 12-15 FPS |

### iOS (iPhone 16, A18 GPU)

| Mode | Conversion | Detection | Total | FPS |
|------|------------|-----------|-------|-----|
| Face Only | 8-12ms | 6-10ms | 14-22ms | ~55 FPS |
| Face + Pose | 10-12ms | 13-19ms | 24-31ms | 32-40 FPS |

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  kwon_mediapipe_landmarker: ^0.0.1
```

### Android Setup

1. Set minimum SDK version in `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        minSdkVersion 24
    }
}
```

2. Add camera permission to `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

### iOS Setup

1. Set minimum deployment target in `ios/Podfile`:

```ruby
platform :ios, '12.0'
```

2. Add camera permission to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required for face and pose detection.</string>
```

## Quick Start

### Initialization

```dart
import 'package:kwon_mediapipe_landmarker/kwon_mediapipe_landmarker.dart';

// Initialize with both face and pose detection
await KwonMediapipeLandmarker.initialize(
  face: true,
  pose: true,
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
```

### Single Image Detection

```dart
import 'dart:io';

final imageBytes = await File('path/to/image.jpg').readAsBytes();
final result = await KwonMediapipeLandmarker.detect(imageBytes);

if (result.hasFace) {
  print('Smile score: ${result.face!.smileScore}');
  print('Eye contact: ${result.face!.eyeContactScore}');
}

if (result.hasPose) {
  print('Posture score: ${result.pose!.postureScore}');
}
```

### Camera Stream Detection

```dart
import 'package:camera/camera.dart';

// Start camera stream
controller.startImageStream((CameraImage image) async {
  final result = await KwonMediapipeLandmarker.detectFromCamera(
    planes: image.planes.map((p) => p.bytes).toList(),
    width: image.width,
    height: image.height,
    rotation: controller.description.sensorOrientation,
    format: 'YUV420',
    bytesPerRow: image.planes.map((p) => p.bytesPerRow).toList(),
  );

  // Process result
  if (result.hasFace) {
    setState(() => _faceResult = result.face);
  }
});
```

### Cleanup

```dart
@override
void dispose() {
  KwonMediapipeLandmarker.dispose();
  super.dispose();
}
```

## API Reference

### KwonMediapipeLandmarker

| Method | Description |
|--------|-------------|
| `initialize({face, pose, faceOptions, poseOptions})` | Initialize the landmarker with specified options |
| `detect(Uint8List imageBytes)` | Detect landmarks in a single image |
| `detectFromCamera({planes, width, height, rotation, format, bytesPerRow})` | Detect landmarks from camera frame |
| `startStream()` | Start streaming detection results |
| `stopStream()` | Stop streaming detection |
| `dispose()` | Release all resources |
| `isInitialized` | Check if landmarker is initialized |
| `isFaceEnabled` | Check if face detection is enabled |
| `isPoseEnabled` | Check if pose detection is enabled |

### FaceOptions

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `numFaces` | int | 1 | Maximum number of faces to detect |
| `minDetectionConfidence` | double | 0.5 | Minimum confidence for detection |
| `minTrackingConfidence` | double | 0.5 | Minimum confidence for tracking |
| `outputBlendshapes` | bool | true | Output 52 blendshape values |
| `outputTransformationMatrix` | bool | false | Output 4x4 transformation matrix |

### PoseOptions

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `numPoses` | int | 1 | Maximum number of poses to detect |
| `minDetectionConfidence` | double | 0.5 | Minimum confidence for detection |
| `minTrackingConfidence` | double | 0.5 | Minimum confidence for tracking |

### LandmarkerResult

| Property | Type | Description |
|----------|------|-------------|
| `face` | FaceResult? | Face detection result (null if not detected) |
| `pose` | PoseResult? | Pose detection result (null if not detected) |
| `timestampMs` | int | Detection timestamp in milliseconds |
| `hasFace` | bool | Whether face was detected |
| `hasPose` | bool | Whether pose was detected |

### FaceResult

| Property | Type | Description |
|----------|------|-------------|
| `landmarks` | List\<Landmark\> | 478 facial landmarks |
| `blendshapes` | Map\<String, double\> | 52 blendshape values (0.0-1.0) |
| `transformationMatrix` | List\<double\>? | 4x4 transformation matrix (optional) |

### PoseResult

| Property | Type | Description |
|----------|------|-------------|
| `landmarks` | List\<Landmark\> | 33 pose landmarks |
| `worldLandmarks` | List\<Landmark\>? | 33 world coordinates in meters |

## Extensions (Helpers)

### FaceResultHelper (14 methods)

| Method | Return | Description |
|--------|--------|-------------|
| `eyeContactScore` | double | Eye contact score (0-1, higher = looking at camera) |
| `smileScore` | double | Smile intensity (0-1) |
| `tensionScore` | double | Tension level from eye squinting and brow lowering |
| `isBlinking` | bool | Either eye is blinking |
| `isBothEyesBlinking` | bool | Both eyes are blinking |
| `mouthOpenness` | double | How much the mouth is open (0-1) |
| `isSpeaking` | bool | Mouth is in speaking position |
| `isSurprised` | bool | Surprised expression detected |
| `isFrowning` | bool | Frowning expression detected |
| `isLipsPursed` | bool | Lips are pursed |
| `horizontalGazeDirection` | double | Horizontal gaze (-1: left, 0: center, 1: right) |
| `verticalGazeDirection` | double | Vertical gaze (-1: up, 0: center, 1: down) |
| `naturalExpressionScore` | double | How natural the expression is (0-1) |
| `symmetryScore` | double | Left-right facial symmetry (0-1) |

**Usage:**

```dart
if (result.hasFace) {
  final face = result.face!;

  // Check eye contact
  if (face.eyeContactScore > 0.8) {
    print('Good eye contact!');
  }

  // Check smile
  if (face.smileScore > 0.5) {
    print('Nice smile!');
  }

  // Detect tension
  if (face.tensionScore > 0.6) {
    print('You seem tense. Try to relax.');
  }
}
```

### PoseResultHelper (19 methods)

| Method | Return | Description |
|--------|--------|-------------|
| `shoulderSymmetryScore` | double | Shoulder alignment score (0-1, higher = more level) |
| `isShoulderTensed` | bool | Shoulders are raised (tension signal) |
| `isLeftHandVisible` | bool | Left hand is visible |
| `isRightHandVisible` | bool | Right hand is visible |
| `areBothHandsVisible` | bool | Both hands are visible |
| `headTilt` | double | Head tilt in radians |
| `headTiltDegrees` | double | Head tilt in degrees |
| `torsoTilt` | double | Torso tilt in radians |
| `torsoTiltDegrees` | double | Torso tilt in degrees |
| `postureScore` | double | Overall posture score (0-1) |
| `isLeftArmRaised` | bool | Left arm is raised above shoulder |
| `isRightArmRaised` | bool | Right arm is raised above shoulder |
| `areBothArmsRaised` | bool | Both arms are raised |
| `isHandNearFace` | bool | Hand is near face (nervous gesture) |
| `isArmsCrossed` | bool | Arms are crossed |
| `shoulderWidth` | double | Shoulder width in normalized coordinates |
| `horizontalPosition` | double | Position in frame (0: left, 0.5: center, 1: right) |
| `centerPositionScore` | double | How centered in frame (0-1) |
| `isUpperBodyVisible` | bool | Upper body is visible |

**Usage:**

```dart
if (result.hasPose) {
  final pose = result.pose!;

  // Check posture
  if (pose.postureScore < 0.6) {
    print('Try to straighten your posture');
  }

  // Detect nervous gestures
  if (pose.isHandNearFace) {
    print('Avoid touching your face');
  }

  // Check positioning
  if (pose.centerPositionScore < 0.7) {
    print('Try to center yourself in the frame');
  }
}
```

## Constants

### FaceLandmarkIndex (Key Points)

| Constant | Index | Description |
|----------|-------|-------------|
| `leftEyeInner` | 133 | Left eye inner corner |
| `leftEyeOuter` | 33 | Left eye outer corner |
| `rightEyeInner` | 362 | Right eye inner corner |
| `rightEyeOuter` | 263 | Right eye outer corner |
| `noseTip` | 1 | Nose tip |
| `mouthLeft` | 61 | Left mouth corner |
| `mouthRight` | 291 | Right mouth corner |
| `chin` | 152 | Chin |
| `leftIrisCenter` | 468 | Left iris center |
| `rightIrisCenter` | 473 | Right iris center |

### PoseLandmarkIndex (All 33 Points)

| Category | Constants |
|----------|-----------|
| **Face** | `nose`, `leftEyeInner`, `leftEye`, `leftEyeOuter`, `rightEyeInner`, `rightEye`, `rightEyeOuter`, `leftEar`, `rightEar`, `mouthLeft`, `mouthRight` |
| **Upper Body** | `leftShoulder`, `rightShoulder`, `leftElbow`, `rightElbow`, `leftWrist`, `rightWrist`, `leftPinky`, `rightPinky`, `leftIndex`, `rightIndex`, `leftThumb`, `rightThumb` |
| **Lower Body** | `leftHip`, `rightHip`, `leftKnee`, `rightKnee`, `leftAnkle`, `rightAnkle`, `leftHeel`, `rightHeel`, `leftFootIndex`, `rightFootIndex` |

### FaceBlendshape (52 Blendshapes)

| Category | Blendshapes |
|----------|-------------|
| **Brow (5)** | `browDownLeft`, `browDownRight`, `browInnerUp`, `browOuterUpLeft`, `browOuterUpRight` |
| **Cheek (3)** | `cheekPuff`, `cheekSquintLeft`, `cheekSquintRight` |
| **Eye (14)** | `eyeBlinkLeft`, `eyeBlinkRight`, `eyeLookDownLeft`, `eyeLookDownRight`, `eyeLookInLeft`, `eyeLookInRight`, `eyeLookOutLeft`, `eyeLookOutRight`, `eyeLookUpLeft`, `eyeLookUpRight`, `eyeSquintLeft`, `eyeSquintRight`, `eyeWideLeft`, `eyeWideRight` |
| **Jaw (4)** | `jawForward`, `jawLeft`, `jawOpen`, `jawRight` |
| **Mouth (23)** | `mouthClose`, `mouthDimpleLeft`, `mouthDimpleRight`, `mouthFrownLeft`, `mouthFrownRight`, `mouthFunnel`, `mouthLeft`, `mouthLowerDownLeft`, `mouthLowerDownRight`, `mouthPressLeft`, `mouthPressRight`, `mouthPucker`, `mouthRight`, `mouthRollLower`, `mouthRollUpper`, `mouthShrugLower`, `mouthShrugUpper`, `mouthSmileLeft`, `mouthSmileRight`, `mouthStretchLeft`, `mouthStretchRight`, `mouthUpperUpLeft`, `mouthUpperUpRight` |
| **Nose (2)** | `noseSneerLeft`, `noseSneerRight` |

## Use Cases

### Interview Practice App

```dart
class InterviewFeedback {
  void analyze(LandmarkerResult result) {
    final feedback = <String>[];

    if (result.hasFace) {
      final face = result.face!;

      // Eye contact feedback
      if (face.eyeContactScore < 0.6) {
        feedback.add('Maintain better eye contact with the camera');
      }

      // Expression feedback
      if (face.smileScore < 0.3 && face.tensionScore > 0.4) {
        feedback.add('Try to relax and smile occasionally');
      }
    }

    if (result.hasPose) {
      final pose = result.pose!;

      // Posture feedback
      if (pose.isShoulderTensed) {
        feedback.add('Relax your shoulders');
      }

      if (pose.postureScore < 0.7) {
        feedback.add('Sit up straight');
      }

      // Gesture feedback
      if (pose.isHandNearFace) {
        feedback.add('Avoid touching your face');
      }

      if (pose.isArmsCrossed) {
        feedback.add('Uncross your arms for more open body language');
      }
    }

    return feedback;
  }
}
```

### Presentation Coach

```dart
class PresentationScore {
  double calculate(LandmarkerResult result) {
    double score = 0;
    int factors = 0;

    if (result.hasFace) {
      final face = result.face!;
      score += face.eyeContactScore;
      score += face.naturalExpressionScore;
      score += face.symmetryScore;
      factors += 3;
    }

    if (result.hasPose) {
      final pose = result.pose!;
      score += pose.postureScore;
      score += pose.centerPositionScore;
      score += pose.shoulderSymmetryScore;
      factors += 3;
    }

    return factors > 0 ? score / factors : 0;
  }
}
```

### Real-time Feedback UI

```dart
Widget buildFeedbackOverlay(LandmarkerResult result) {
  return Stack(
    children: [
      // Eye contact indicator
      if (result.hasFace)
        Positioned(
          top: 10,
          left: 10,
          child: Row(
            children: [
              Icon(
                Icons.visibility,
                color: result.face!.eyeContactScore > 0.7
                    ? Colors.green
                    : Colors.orange,
              ),
              SizedBox(width: 8),
              Text('${(result.face!.eyeContactScore * 100).toInt()}%'),
            ],
          ),
        ),

      // Posture indicator
      if (result.hasPose)
        Positioned(
          top: 10,
          right: 10,
          child: Row(
            children: [
              Icon(
                Icons.accessibility_new,
                color: result.pose!.postureScore > 0.7
                    ? Colors.green
                    : Colors.orange,
              ),
              SizedBox(width: 8),
              Text('${(result.pose!.postureScore * 100).toInt()}%'),
            ],
          ),
        ),
    ],
  );
}
```

## Error Handling

The plugin provides structured error handling through `LandmarkerException`:

```dart
try {
  await KwonMediapipeLandmarker.initialize(face: true);
} on LandmarkerException catch (e) {
  switch (e.error) {
    case LandmarkerError.notInitialized:
      print('Landmarker not initialized');
      break;
    case LandmarkerError.modelLoadFailed:
      print('Failed to load model files');
      break;
    case LandmarkerError.invalidImage:
      print('Invalid image format');
      break;
    case LandmarkerError.detectionFailed:
      print('Detection failed');
      break;
    case LandmarkerError.initializationFailed:
      print('Initialization failed: ${e.message}');
      break;
    default:
      print('Error: ${e.code} - ${e.message}');
  }
}
```

## Troubleshooting

### Common Issues

**1. "NOT_INITIALIZED" error**
- Make sure to call `KwonMediapipeLandmarker.initialize()` before using `detect()` or `detectFromCamera()`
- Check that initialization completed successfully

**2. "MODEL_LOAD_FAILED" error**
- Verify that model files exist in the correct locations:
  - Android: `android/src/main/assets/face_landmarker.task`, `pose_landmarker_lite.task`
  - iOS: `ios/Assets/face_landmarker.task`, `pose_landmarker_lite.task`

**3. "INVALID_IMAGE" error**
- Ensure image data is in a supported format (JPEG, PNG)
- For camera frames, verify YUV data planes are correctly passed

**4. Low FPS on Android**
- This is expected due to MediaPipe running on CPU on Android
- Consider reducing resolution or using face-only mode for better performance

**5. Camera permission denied**
- Add camera permission to AndroidManifest.xml and Info.plist
- Request permission at runtime using `permission_handler` package

**6. MediaPipe warnings in console**
- Warnings like `landmark_projection_calculator.cc:186` are internal MediaPipe messages and can be safely ignored

### Platform-Specific Notes

**Android:**
- Minimum SDK: 24
- Uses native YUV-to-RGB conversion for performance
- Performance varies by device GPU/CPU

**iOS:**
- Minimum iOS: 12.0
- Uses Core Video for optimal frame processing
- Significantly faster than Android due to GPU acceleration

## License

```
Copyright 2026 kwon

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
