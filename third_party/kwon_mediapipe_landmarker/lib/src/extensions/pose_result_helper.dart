import 'dart:math';

import '../result.dart';
import '../constants/pose_landmark_index.dart';
import '../landmark.dart';
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

  /// 어깨와 발의 X 좌표 정렬 (스쿼트 자세 검증용)
  ///
  /// 값이 작을수록 잘 정렬됨 (0.0 = 완벽한 정렬)
  double get shoulderFeetAlignment {
    final leftShoulder = landmarks[PoseLandmarkIndex.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkIndex.rightShoulder];
    final leftAnkle = landmarks[PoseLandmarkIndex.leftAnkle];
    final rightAnkle = landmarks[PoseLandmarkIndex.rightAnkle];

    // 어깨의 평균 X 좌표
    final shoulderCenterX = (leftShoulder.x + rightShoulder.x) / 2;

    // 발의 평균 X 좌표
    final feetCenterX = (leftAnkle.x + rightAnkle.x) / 2;

    // X 좌표 차이 반환 (0.0에 가까울수록 정렬됨)
    return (shoulderCenterX - feetCenterX).abs();
  }

  /// 스쿼트 자세 검증 (어깨와 발이 정렬되었는지 확인)
  ///
  /// offset: 허용 오차 범위 (기본값: 0.5)
  /// true이면 자세가 올바름
  bool isSquatFormCorrect({double offset = 0.1}) {
    final alignment = shoulderFeetAlignment;
    final leftAnkle = landmarks[PoseLandmarkIndex.leftAnkle];
    final rightAnkle = landmarks[PoseLandmarkIndex.rightAnkle];

    // 발이 감지되어야 함
    if ((leftAnkle.visibility ?? 0) < 0.5 ||
        (rightAnkle.visibility ?? 0) < 0.5) {
      return false;
    }

    // 어깨와 발이 지정된 오차 범위 내에 정렬되어야 함
    return alignment <= offset;
  }

  double get squatKneeAngle {
    final leftHip = landmarks[PoseLandmarkIndex.leftHip];
    final leftKnee = landmarks[PoseLandmarkIndex.leftKnee];
    final leftAnkle = landmarks[PoseLandmarkIndex.leftAnkle];

    final rightHip = landmarks[PoseLandmarkIndex.rightHip];
    final rightKnee = landmarks[PoseLandmarkIndex.rightKnee];
    final rightAnkle = landmarks[PoseLandmarkIndex.rightAnkle];

    if ((leftKnee.visibility ?? 0) < 0.5 || (rightKnee.visibility ?? 0) < 0.5) return 0;

    final leftAngle = getAngleBetweenJoints(leftHip, leftKnee, leftAnkle);
    final rightAngle = getAngleBetweenJoints(rightHip, rightKnee, rightAnkle);

    return (leftAngle + rightAngle) / 2;
  }

  /// 스쿼트 내려간 자세 감지 (무릎 각도 100도 이하)
  bool get isSquatDownPosition {
    // 90 is perfectly parallel. 100 is a forgiving but decent depth.
    return squatKneeAngle > 0 && squatKneeAngle < 100;
  }

  /// 스쿼트 일어선 자세 감지 (무릎 각도 160도 이상)
  bool get isSquatUpPosition {
    // 180 is fully standing straight.
    return squatKneeAngle > 160;
  }

  /// 세 관절 사이의 각도 계산 (도 단위)
  ///
  /// joint1 -> joint2 -> joint3 순서로 각도 계산
  /// 반환값: 0 ~ 180도
  double getAngleBetweenJoints(Landmark joint1, Landmark joint2, Landmark joint3){    // 벡터 계산: joint2에서 joint1으로의 벡터
    final v1x = joint1.x - joint2.x;
    final v1y = joint1.y - joint2.y;

    // 벡터 계산: joint2에서 joint3으로의 벡터
    final v2x = joint3.x - joint2.x;
    final v2y = joint3.y - joint2.y;

    // 내적 계산
    final dotProduct = v1x * v2x + v1y * v2y;

    // 크기 계산
    final magnitude1 = sqrt(v1x * v1x + v1y * v1y);
    final magnitude2 = sqrt(v2x * v2x + v2y * v2y);

    if (magnitude1 == 0 || magnitude2 == 0) return 0;

    // 코사인 값 계산
    final cosAngle = dotProduct / (magnitude1 * magnitude2);
    final clampedCosAngle = cosAngle.clamp(-1.0, 1.0);

    // 라디안을 도로 변환
    return acos(clampedCosAngle) * 180 / pi;
  }

  /// 푸쉬업 시작 위치 검증 (팔이 펴진 상태)
  ///
  /// 어깨-팔꿈치-손목이 거의 일직선 (180도 근처)
  bool isPushupStartingPositionCorrect({double angleTolerance = 30}) {
    final leftShoulder = landmarks[PoseLandmarkIndex.leftShoulder];
    final leftElbow = landmarks[PoseLandmarkIndex.leftElbow];
    final leftWrist = landmarks[PoseLandmarkIndex.leftWrist];
    final rightShoulder = landmarks[PoseLandmarkIndex.rightShoulder];
    final rightElbow = landmarks[PoseLandmarkIndex.rightElbow];
    final rightWrist = landmarks[PoseLandmarkIndex.rightWrist];

    // 관절이 감지되어야 함
    if ((leftShoulder.visibility ?? 0) < 0.5 ||
        (leftElbow.visibility ?? 0) < 0.5 ||
        (leftWrist.visibility ?? 0) < 0.5 ||
        (rightShoulder.visibility ?? 0) < 0.5 ||
        (rightElbow.visibility ?? 0) < 0.5 ||
        (rightWrist.visibility ?? 0) < 0.5) {
      return false;
    }

    // 양팔의 각도 계산
    final leftArmAngle = getAngleBetweenJoints(leftShoulder, leftElbow, leftWrist);
    final rightArmAngle = getAngleBetweenJoints(rightShoulder, rightElbow, rightWrist);

    // 180도에 가까워야 함 (펴진 상태)
    final leftCorrect = (180 - leftArmAngle).abs() < angleTolerance;
    final rightCorrect = (180 - rightArmAngle).abs() < angleTolerance;

    return leftCorrect && rightCorrect;
  }

  /// 푸쉬업 내려간 위치 검증 (팔이 구부러진 상태)
  ///
  /// 어깨-팔꿈치-손목이 약 90도
  bool isPushupBottomPositionCorrect({double angleTolerance = 30}) {
    final leftShoulder = landmarks[PoseLandmarkIndex.leftShoulder];
    final leftElbow = landmarks[PoseLandmarkIndex.leftElbow];
    final leftWrist = landmarks[PoseLandmarkIndex.leftWrist];
    final rightShoulder = landmarks[PoseLandmarkIndex.rightShoulder];
    final rightElbow = landmarks[PoseLandmarkIndex.rightElbow];
    final rightWrist = landmarks[PoseLandmarkIndex.rightWrist];

    // 관절이 감지되어야 함
    if ((leftShoulder.visibility ?? 0) < 0.5 ||
        (leftElbow.visibility ?? 0) < 0.5 ||
        (leftWrist.visibility ?? 0) < 0.5 ||
        (rightShoulder.visibility ?? 0) < 0.5 ||
        (rightElbow.visibility ?? 0) < 0.5 ||
        (rightWrist.visibility ?? 0) < 0.5) {
      return false;
    }

    // 양팔의 각도 계산
    final leftArmAngle = getAngleBetweenJoints(leftShoulder, leftElbow, leftWrist);
    final rightArmAngle = getAngleBetweenJoints(rightShoulder, rightElbow, rightWrist);

    // 90도에 가까워야 함 (구부러진 상태)
    final leftCorrect = (90 - leftArmAngle).abs() < angleTolerance;
    final rightCorrect = (90 - rightArmAngle).abs() < angleTolerance;

    return leftCorrect && rightCorrect;
  }

  /// 푸쉬업 팔 각도 (양팔의 평균)
  double get pushupArmAngle {
    final leftShoulder = landmarks[PoseLandmarkIndex.leftShoulder];
    final leftElbow = landmarks[PoseLandmarkIndex.leftElbow];
    final leftWrist = landmarks[PoseLandmarkIndex.leftWrist];
    final rightShoulder = landmarks[PoseLandmarkIndex.rightShoulder];
    final rightElbow = landmarks[PoseLandmarkIndex.rightElbow];
    final rightWrist = landmarks[PoseLandmarkIndex.rightWrist];

    if ((leftElbow.visibility ?? 0) < 0.5 || (rightElbow.visibility ?? 0) < 0.5) {
      return 0;
    }

    final leftAngle = getAngleBetweenJoints(leftShoulder, leftElbow, leftWrist);
    final rightAngle = getAngleBetweenJoints(rightShoulder, rightElbow, rightWrist);

    return (leftAngle + rightAngle) / 2;
  }

  double get pushupTorsoArmAngle {
    final leftHip = landmarks[PoseLandmarkIndex.leftHip];
    final leftShoulder = landmarks[PoseLandmarkIndex.leftShoulder];
    final leftElbow = landmarks[PoseLandmarkIndex.leftElbow];
    
    final rightHip = landmarks[PoseLandmarkIndex.rightHip];
    final rightShoulder = landmarks[PoseLandmarkIndex.rightShoulder];
    final rightElbow = landmarks[PoseLandmarkIndex.rightElbow];

    // 어깨가 보이지 않으면 0 반환
    if ((leftShoulder.visibility ?? 0) < 0.5 || (rightShoulder.visibility ?? 0) < 0.5) {
      return 0;
    }

    // 어깨를 꼭짓점으로 하여 골반(몸통)과 팔꿈치(팔) 사이의 각도 계산
    final leftAngle = getAngleBetweenJoints(leftHip, leftShoulder, leftElbow);
    final rightAngle = getAngleBetweenJoints(rightHip, rightShoulder, rightElbow);

    return (leftAngle + rightAngle) / 2;
  }

  double get pushupBodyAngle {
    final leftShoulder = landmarks[PoseLandmarkIndex.leftShoulder];
    final leftHip = landmarks[PoseLandmarkIndex.leftHip];
    final leftAnkle = landmarks[PoseLandmarkIndex.leftAnkle];

    final rightShoulder = landmarks[PoseLandmarkIndex.rightShoulder];
    final rightHip = landmarks[PoseLandmarkIndex.rightHip];
    final rightAnkle = landmarks[PoseLandmarkIndex.rightAnkle];

    // 관절이 보이지 않으면 180(정상)으로 간주하여 잘못된 페널티 방지
    if ((leftHip.visibility ?? 0) < 0.5 || (rightHip.visibility ?? 0) < 0.5) {
      return 180.0; 
    }

    final leftAngle = getAngleBetweenJoints(leftShoulder, leftHip, leftAnkle);
    final rightAngle = getAngleBetweenJoints(rightShoulder, rightHip, rightAnkle);

    return (leftAngle + rightAngle) / 2;
  }
  /// 푸쉬업 팔꿈치 벌어짐 검증 (45도 유지)
  ///
  /// targetAngle: 이상적인 각도 (기본 45도 - 화살표 모양)
  /// angleTolerance: 허용 오차 (기본 20도 -> 25~65도 사이면 올바른 자세로 판정)
  bool isPushupElbowFlareCorrect({double targetAngle = 45, double angleTolerance = 20}) {
    final leftHip = landmarks[PoseLandmarkIndex.leftHip];
    final leftShoulder = landmarks[PoseLandmarkIndex.leftShoulder];
    final leftElbow = landmarks[PoseLandmarkIndex.leftElbow];
    
    final rightHip = landmarks[PoseLandmarkIndex.rightHip];
    final rightShoulder = landmarks[PoseLandmarkIndex.rightShoulder];
    final rightElbow = landmarks[PoseLandmarkIndex.rightElbow];

    if ((leftHip.visibility ?? 0) < 0.5 ||
        (leftShoulder.visibility ?? 0) < 0.5 ||
        (leftElbow.visibility ?? 0) < 0.5 ||
        (rightHip.visibility ?? 0) < 0.5 ||
        (rightShoulder.visibility ?? 0) < 0.5 ||
        (rightElbow.visibility ?? 0) < 0.5) {
      return false;
    }

    final leftAngle = getAngleBetweenJoints(leftHip, leftShoulder, leftElbow);
    final rightAngle = getAngleBetweenJoints(rightHip, rightShoulder, rightElbow);

    final leftCorrect = (leftAngle - targetAngle).abs() <= angleTolerance;
    final rightCorrect = (rightAngle - targetAngle).abs() <= angleTolerance;

    return leftCorrect && rightCorrect;
  }

  /// 윗몸일으키기 몸통 각도 (누운 상태 대비 들어올린 정도)
  ///
  /// 0도: 누운 상태 (수평), 90도: 일어난 상태 (수직)
  /// 반환값: 0 ~ 90도
  double get situpTorsoAngle {
    final leftHip = landmarks[PoseLandmarkIndex.leftHip];
    final rightHip = landmarks[PoseLandmarkIndex.rightHip];
    final leftShoulder = landmarks[PoseLandmarkIndex.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkIndex.rightShoulder];

    // 중심점 계산
    final hipCenterX = (leftHip.x + rightHip.x) / 2;
    final hipCenterY = (leftHip.y + rightHip.y) / 2;
    final shoulderCenterX = (leftShoulder.x + rightShoulder.x) / 2;
    final shoulderCenterY = (leftShoulder.y + rightShoulder.y) / 2;

    // 골반에서 어깨로의 벡터
    final dx = shoulderCenterX - hipCenterX;
    final dy = shoulderCenterY - hipCenterY;

    // 수평축으로부터의 각도 (MediaPipe에서 y는 아래로 증가)
    // 누운 상태: dy ≈ 0, 각도 ≈ 0
    // 앉은 상태: dy < 0 (어깨가 골반 위), 각도 증가
    final angleRad = atan2(-dy, dx); // dy를 음수로 처리 (y는 아래로 증가하므로)
    final angleDeg = angleRad * 180 / pi;

    // 0-90 범위로 정규화
    return angleDeg.abs().clamp(0.0, 90.0);
  }

  /// 윗몸일으키기 누운 자세 감지
  ///
  /// 몸통 각도가 30도 미만일 때 (거의 누운 상태)
  bool get isSitupDownPosition {
    final leftHip = landmarks[PoseLandmarkIndex.leftHip];
    final leftShoulder = landmarks[PoseLandmarkIndex.leftShoulder];

    if ((leftHip.visibility ?? 0) < 0.5 ||
        (leftShoulder.visibility ?? 0) < 0.5) {
      return false;
    }

    return situpTorsoAngle < 30;
  }

  /// 윗몸일으키기 앉은 자세 감지
  ///
  /// 몸통 각도가 60도 이상일 때 (충분히 들어올린 상태)
  bool get isSitupUpPosition {
    final leftHip = landmarks[PoseLandmarkIndex.leftHip];
    final leftShoulder = landmarks[PoseLandmarkIndex.leftShoulder];

    if ((leftHip.visibility ?? 0) < 0.5 ||
        (leftShoulder.visibility ?? 0) < 0.5) {
      return false;
    }

    return situpTorsoAngle >= 60;
  }
}
