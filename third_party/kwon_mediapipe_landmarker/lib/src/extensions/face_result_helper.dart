import '../result.dart';
import '../constants/face_blendshape.dart';

/// FaceResult 편의 확장
extension FaceResultHelper on FaceResult {
  /// 시선 점수 (0.0~1.0, 카메라 정면 응시일수록 높음)
  ///
  /// 눈이 상하좌우로 벗어날수록 점수가 낮아짐
  double get eyeContactScore {
    final lookInL = blendshapes[FaceBlendshape.eyeLookInLeft] ?? 0;
    final lookInR = blendshapes[FaceBlendshape.eyeLookInRight] ?? 0;
    final lookOutL = blendshapes[FaceBlendshape.eyeLookOutLeft] ?? 0;
    final lookOutR = blendshapes[FaceBlendshape.eyeLookOutRight] ?? 0;
    final lookUpL = blendshapes[FaceBlendshape.eyeLookUpLeft] ?? 0;
    final lookUpR = blendshapes[FaceBlendshape.eyeLookUpRight] ?? 0;
    final lookDownL = blendshapes[FaceBlendshape.eyeLookDownLeft] ?? 0;
    final lookDownR = blendshapes[FaceBlendshape.eyeLookDownRight] ?? 0;

    final avgDeviation = (lookInL +
            lookInR +
            lookOutL +
            lookOutR +
            lookUpL +
            lookUpR +
            lookDownL +
            lookDownR) /
        8;
    return (1.0 - avgDeviation).clamp(0.0, 1.0);
  }

  /// 미소 점수 (0.0~1.0)
  ///
  /// 양쪽 입꼬리 올라감 정도의 평균
  double get smileScore {
    final smileL = blendshapes[FaceBlendshape.mouthSmileLeft] ?? 0;
    final smileR = blendshapes[FaceBlendshape.mouthSmileRight] ?? 0;
    return ((smileL + smileR) / 2).clamp(0.0, 1.0);
  }

  /// 긴장도 점수 (0.0~1.0, 눈 찡그림 + 눈썹 내림)
  ///
  /// 높을수록 긴장/불편함 표현
  double get tensionScore {
    final squintL = blendshapes[FaceBlendshape.eyeSquintLeft] ?? 0;
    final squintR = blendshapes[FaceBlendshape.eyeSquintRight] ?? 0;
    final browDownL = blendshapes[FaceBlendshape.browDownLeft] ?? 0;
    final browDownR = blendshapes[FaceBlendshape.browDownRight] ?? 0;
    return ((squintL + squintR + browDownL + browDownR) / 4).clamp(0.0, 1.0);
  }

  /// 눈 깜빡임 감지
  ///
  /// 한쪽 눈이라도 50% 이상 감기면 true
  bool get isBlinking {
    final blinkL = blendshapes[FaceBlendshape.eyeBlinkLeft] ?? 0;
    final blinkR = blendshapes[FaceBlendshape.eyeBlinkRight] ?? 0;
    return blinkL > 0.5 || blinkR > 0.5;
  }

  /// 양쪽 눈 모두 깜빡임 감지
  bool get isBothEyesBlinking {
    final blinkL = blendshapes[FaceBlendshape.eyeBlinkLeft] ?? 0;
    final blinkR = blendshapes[FaceBlendshape.eyeBlinkRight] ?? 0;
    return blinkL > 0.5 && blinkR > 0.5;
  }

  /// 입 벌림 정도 (0.0~1.0)
  double get mouthOpenness {
    return blendshapes[FaceBlendshape.jawOpen] ?? 0;
  }

  /// 말하고 있는지 감지 (입이 적당히 열려있음)
  ///
  /// 입이 15%~80% 열려있으면 말하는 중으로 판단
  bool get isSpeaking {
    final openness = mouthOpenness;
    return openness > 0.15 && openness < 0.8;
  }

  /// 놀람 표정 감지
  ///
  /// 눈이 크게 떠지고 눈썹이 올라감
  bool get isSurprised {
    final eyeWideL = blendshapes[FaceBlendshape.eyeWideLeft] ?? 0;
    final eyeWideR = blendshapes[FaceBlendshape.eyeWideRight] ?? 0;
    final browInnerUp = blendshapes[FaceBlendshape.browInnerUp] ?? 0;
    return (eyeWideL > 0.3 || eyeWideR > 0.3) && browInnerUp > 0.3;
  }

  /// 찡그림 표정 감지
  ///
  /// 입꼬리가 내려가고 눈썹이 찌푸려짐
  bool get isFrowning {
    final frownL = blendshapes[FaceBlendshape.mouthFrownLeft] ?? 0;
    final frownR = blendshapes[FaceBlendshape.mouthFrownRight] ?? 0;
    final browDownL = blendshapes[FaceBlendshape.browDownLeft] ?? 0;
    final browDownR = blendshapes[FaceBlendshape.browDownRight] ?? 0;
    return (frownL > 0.3 || frownR > 0.3) && (browDownL > 0.3 || browDownR > 0.3);
  }

  /// 입술 오므림 감지 (긴장/집중)
  bool get isLipsPursed {
    final pucker = blendshapes[FaceBlendshape.mouthPucker] ?? 0;
    final funnel = blendshapes[FaceBlendshape.mouthFunnel] ?? 0;
    return pucker > 0.3 || funnel > 0.3;
  }

  /// 수평 시선 방향 (-1.0: 완전 왼쪽, 0.0: 정면, 1.0: 완전 오른쪽)
  ///
  /// 음수: 왼쪽 보기, 양수: 오른쪽 보기
  double get horizontalGazeDirection {
    // 왼쪽 눈의 시선
    final leftEyeOut = blendshapes[FaceBlendshape.eyeLookOutLeft] ?? 0;
    final leftEyeIn = blendshapes[FaceBlendshape.eyeLookInLeft] ?? 0;

    // 오른쪽 눈의 시선
    final rightEyeOut = blendshapes[FaceBlendshape.eyeLookOutRight] ?? 0;
    final rightEyeIn = blendshapes[FaceBlendshape.eyeLookInRight] ?? 0;

    // 왼쪽 보기: 왼쪽 눈 Out + 오른쪽 눈 In
    // 오른쪽 보기: 왼쪽 눈 In + 오른쪽 눈 Out
    final lookLeft = (leftEyeOut + rightEyeIn) / 2;
    final lookRight = (leftEyeIn + rightEyeOut) / 2;

    return (lookRight - lookLeft).clamp(-1.0, 1.0);
  }

  /// 수직 시선 방향 (-1.0: 완전 위, 0.0: 정면, 1.0: 완전 아래)
  ///
  /// 음수: 위 보기, 양수: 아래 보기
  double get verticalGazeDirection {
    final lookUpL = blendshapes[FaceBlendshape.eyeLookUpLeft] ?? 0;
    final lookUpR = blendshapes[FaceBlendshape.eyeLookUpRight] ?? 0;
    final lookDownL = blendshapes[FaceBlendshape.eyeLookDownLeft] ?? 0;
    final lookDownR = blendshapes[FaceBlendshape.eyeLookDownRight] ?? 0;

    final lookUp = (lookUpL + lookUpR) / 2;
    final lookDown = (lookDownL + lookDownR) / 2;

    return (lookDown - lookUp).clamp(-1.0, 1.0);
  }

  /// 표정 자연스러움 점수 (0.0~1.0)
  ///
  /// 극단적인 표정 없이 자연스러운 상태일수록 높음
  double get naturalExpressionScore {
    // 극단적인 표정들의 평균
    final extremes = [
      blendshapes[FaceBlendshape.eyeWideLeft] ?? 0,
      blendshapes[FaceBlendshape.eyeWideRight] ?? 0,
      blendshapes[FaceBlendshape.mouthFrownLeft] ?? 0,
      blendshapes[FaceBlendshape.mouthFrownRight] ?? 0,
      blendshapes[FaceBlendshape.browInnerUp] ?? 0,
      blendshapes[FaceBlendshape.jawOpen] ?? 0,
    ];

    final avgExtreme = extremes.reduce((a, b) => a + b) / extremes.length;
    return (1.0 - avgExtreme).clamp(0.0, 1.0);
  }

  /// 좌우 대칭 점수 (0.0~1.0, 대칭일수록 높음)
  ///
  /// 얼굴 표정의 좌우 균형 측정
  double get symmetryScore {
    final pairs = [
      [FaceBlendshape.eyeBlinkLeft, FaceBlendshape.eyeBlinkRight],
      [FaceBlendshape.eyeSquintLeft, FaceBlendshape.eyeSquintRight],
      [FaceBlendshape.browDownLeft, FaceBlendshape.browDownRight],
      [FaceBlendshape.mouthSmileLeft, FaceBlendshape.mouthSmileRight],
      [FaceBlendshape.cheekSquintLeft, FaceBlendshape.cheekSquintRight],
    ];

    double totalDiff = 0;
    for (final pair in pairs) {
      final left = blendshapes[pair[0]] ?? 0;
      final right = blendshapes[pair[1]] ?? 0;
      totalDiff += (left - right).abs();
    }

    final avgDiff = totalDiff / pairs.length;
    return (1.0 - avgDiff).clamp(0.0, 1.0);
  }
}
