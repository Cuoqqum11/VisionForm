import 'dart:math';

import '../result.dart';
import '../constants/pose_landmark_index.dart';

/// PoseResult 편의 확장
extension PoseResultHelper on PoseResult {
  /// 어깨 대칭 점수 (0.0~1.0, 수평일수록 높음)
  ///
  /// 어깨가 기울어질수록 점수가 낮아짐
  double get shoulderSymmetryScore {
    final leftShoulder = landmarks[PoseLandmarkIndex.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkIndex.rightShoulder];

    // Y좌표 차이로 기울기 계산 (0이면 완전 수평)
    final yDiff = (leftShoulder.y - rightShoulder.y).abs();
    return (1.0 - yDiff * 5).clamp(0.0, 1.0); // 0.2 차이면 0점
  }

  /// 어깨 움츠림 감지 (귀와 어깨 거리 기반)
  ///
  /// 긴장해서 어깨가 올라갔을 때 true
  bool get isShoulderTensed {
    final leftEar = landmarks[PoseLandmarkIndex.leftEar];
    final leftShoulder = landmarks[PoseLandmarkIndex.leftShoulder];
    final rightEar = landmarks[PoseLandmarkIndex.rightEar];
    final rightShoulder = landmarks[PoseLandmarkIndex.rightShoulder];

    // 절대값 사용 (iOS/Android 좌표계 차이 대응)
    final leftDist = (leftShoulder.y - leftEar.y).abs();
    final rightDist = (rightShoulder.y - rightEar.y).abs();
    final avgDist = (leftDist + rightDist) / 2;

    return avgDist < 0.1; // 귀-어깨 거리가 너무 가까우면 움츠림
  }

  /// 왼손 보임 여부
  bool get isLeftHandVisible {
    final wrist = landmarks[PoseLandmarkIndex.leftWrist];
    return (wrist.visibility ?? 0) > 0.5;
  }

  /// 오른손 보임 여부
  bool get isRightHandVisible {
    final wrist = landmarks[PoseLandmarkIndex.rightWrist];
    return (wrist.visibility ?? 0) > 0.5;
  }

  /// 양손 모두 보임 여부
  bool get areBothHandsVisible {
    return isLeftHandVisible && isRightHandVisible;
  }

  /// 고개 기울기 (라디안, 양수=오른쪽 기울임)
  ///
  /// 양수: 오른쪽으로 기울임, 음수: 왼쪽으로 기울임
  double get headTilt {
    final leftEar = landmarks[PoseLandmarkIndex.leftEar];
    final rightEar = landmarks[PoseLandmarkIndex.rightEar];

    final dx = rightEar.x - leftEar.x;
    final dy = rightEar.y - leftEar.y;
    return atan2(dy, dx);
  }

  /// 고개 기울기 (도 단위)
  double get headTiltDegrees {
    return headTilt * 180 / pi;
  }

  /// 몸통 기울기 (라디안, 양수=오른쪽 기울임)
  double get torsoTilt {
    final leftShoulder = landmarks[PoseLandmarkIndex.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkIndex.rightShoulder];

    final dx = rightShoulder.x - leftShoulder.x;
    final dy = rightShoulder.y - leftShoulder.y;
    return atan2(dy, dx);
  }

  /// 몸통 기울기 (도 단위)
  double get torsoTiltDegrees {
    return torsoTilt * 180 / pi;
  }

  /// 자세 바름 점수 (0.0~1.0)
  ///
  /// 어깨 수평 + 고개 수평 + 어깨 펴짐 종합
  double get postureScore {
    final shoulderScore = shoulderSymmetryScore;
    final headScore = (1.0 - headTiltDegrees.abs() / 30).clamp(0.0, 1.0);
    final tensionScore = isShoulderTensed ? 0.0 : 1.0;

    return ((shoulderScore + headScore + tensionScore) / 3).clamp(0.0, 1.0);
  }

  /// 왼팔 들어올림 감지 (어깨보다 손목이 위에 있음)
  bool get isLeftArmRaised {
    final shoulder = landmarks[PoseLandmarkIndex.leftShoulder];
    final wrist = landmarks[PoseLandmarkIndex.leftWrist];
    return wrist.y < shoulder.y && (wrist.visibility ?? 0) > 0.5;
  }

  /// 오른팔 들어올림 감지
  bool get isRightArmRaised {
    final shoulder = landmarks[PoseLandmarkIndex.rightShoulder];
    final wrist = landmarks[PoseLandmarkIndex.rightWrist];
    return wrist.y < shoulder.y && (wrist.visibility ?? 0) > 0.5;
  }

  /// 양팔 모두 들어올림 감지
  bool get areBothArmsRaised {
    return isLeftArmRaised && isRightArmRaised;
  }

  /// 손이 얼굴 근처에 있는지 감지
  ///
  /// 손으로 얼굴 만지기 (긴장 신호) 감지에 유용
  bool get isHandNearFace {
    final nose = landmarks[PoseLandmarkIndex.nose];
    final leftWrist = landmarks[PoseLandmarkIndex.leftWrist];
    final rightWrist = landmarks[PoseLandmarkIndex.rightWrist];

    // 코와 손목 사이 거리 계산
    double distance(double x1, double y1, double x2, double y2) {
      return sqrt(pow(x2 - x1, 2) + pow(y2 - y1, 2));
    }

    final leftDist = distance(nose.x, nose.y, leftWrist.x, leftWrist.y);
    final rightDist = distance(nose.x, nose.y, rightWrist.x, rightWrist.y);

    // visibility 체크 후 거리 확인 (정규화 좌표 기준 0.2 이내)
    final leftNear =
        (leftWrist.visibility ?? 0) > 0.5 && leftDist < 0.2;
    final rightNear =
        (rightWrist.visibility ?? 0) > 0.5 && rightDist < 0.2;

    return leftNear || rightNear;
  }

  /// 팔짱 끼기 감지
  ///
  /// 양 손목이 몸 중앙 근처에 교차해 있음
  bool get isArmsCrossed {
    final leftWrist = landmarks[PoseLandmarkIndex.leftWrist];
    final rightWrist = landmarks[PoseLandmarkIndex.rightWrist];
    final leftShoulder = landmarks[PoseLandmarkIndex.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkIndex.rightShoulder];

    // 양 손목이 모두 보이는지 확인
    if ((leftWrist.visibility ?? 0) < 0.5 ||
        (rightWrist.visibility ?? 0) < 0.5) {
      return false;
    }

    // 몸 중앙 X 좌표
    final centerX = (leftShoulder.x + rightShoulder.x) / 2;

    // 왼손이 몸 오른쪽에, 오른손이 몸 왼쪽에 있으면 팔짱
    final leftCrossed = leftWrist.x > centerX;
    final rightCrossed = rightWrist.x < centerX;

    // 손목이 어깨와 엉덩이 사이 높이에 있는지 확인
    final avgShoulderY = (leftShoulder.y + rightShoulder.y) / 2;
    final leftHip = landmarks[PoseLandmarkIndex.leftHip];
    final rightHip = landmarks[PoseLandmarkIndex.rightHip];
    final avgHipY = (leftHip.y + rightHip.y) / 2;

    final wristsInTorsoRange =
        leftWrist.y > avgShoulderY &&
        leftWrist.y < avgHipY &&
        rightWrist.y > avgShoulderY &&
        rightWrist.y < avgHipY;

    return leftCrossed && rightCrossed && wristsInTorsoRange;
  }

  /// 어깨 너비 (정규화 좌표)
  double get shoulderWidth {
    final left = landmarks[PoseLandmarkIndex.leftShoulder];
    final right = landmarks[PoseLandmarkIndex.rightShoulder];
    return (right.x - left.x).abs();
  }

  /// 프레임 내 위치 (0.0: 왼쪽 끝, 0.5: 중앙, 1.0: 오른쪽 끝)
  ///
  /// 발표자가 화면 중앙에 있는지 확인에 유용
  double get horizontalPosition {
    final left = landmarks[PoseLandmarkIndex.leftShoulder];
    final right = landmarks[PoseLandmarkIndex.rightShoulder];
    return (left.x + right.x) / 2;
  }

  /// 화면 중앙 위치 점수 (0.0~1.0, 중앙일수록 높음)
  double get centerPositionScore {
    final pos = horizontalPosition;
    // 0.5에서 멀어질수록 점수 감소
    return (1.0 - (pos - 0.5).abs() * 2).clamp(0.0, 1.0);
  }

  /// 상체 보임 여부 (어깨와 엉덩이가 모두 감지됨)
  bool get isUpperBodyVisible {
    final leftShoulder = landmarks[PoseLandmarkIndex.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkIndex.rightShoulder];

    return (leftShoulder.visibility ?? 0) > 0.5 &&
        (rightShoulder.visibility ?? 0) > 0.5;
  }
}
