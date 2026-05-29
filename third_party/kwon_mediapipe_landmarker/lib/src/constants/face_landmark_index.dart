/// Face 랜드마크 개수 상수
class FaceLandmarkCount {
  FaceLandmarkCount._();

  /// 전체 랜드마크 수 (기본 468 + 홍채 10)
  static const int total = 478;

  /// 기본 얼굴 메쉬 랜드마크 수
  static const int base = 468;

  /// 홍채 랜드마크 수
  static const int iris = 10;
}

/// 주요 Face 랜드마크 인덱스 (자주 사용하는 것만)
class FaceLandmarkIndex {
  FaceLandmarkIndex._();

  // ===== 눈 (Eyes) =====
  /// 왼쪽 눈 안쪽 모서리
  static const int leftEyeInner = 133;

  /// 왼쪽 눈 바깥쪽 모서리
  static const int leftEyeOuter = 33;

  /// 오른쪽 눈 안쪽 모서리
  static const int rightEyeInner = 362;

  /// 오른쪽 눈 바깥쪽 모서리
  static const int rightEyeOuter = 263;

  /// 왼쪽 눈 중앙 위
  static const int leftEyeTop = 159;

  /// 왼쪽 눈 중앙 아래
  static const int leftEyeBottom = 145;

  /// 오른쪽 눈 중앙 위
  static const int rightEyeTop = 386;

  /// 오른쪽 눈 중앙 아래
  static const int rightEyeBottom = 374;

  // ===== 눈썹 (Eyebrows) =====
  /// 왼쪽 눈썹 안쪽
  static const int leftEyebrowInner = 107;

  /// 왼쪽 눈썹 바깥쪽
  static const int leftEyebrowOuter = 46;

  /// 오른쪽 눈썹 안쪽
  static const int rightEyebrowInner = 336;

  /// 오른쪽 눈썹 바깥쪽
  static const int rightEyebrowOuter = 276;

  // ===== 코 (Nose) =====
  /// 코끝
  static const int noseTip = 1;

  /// 코 다리 (콧등)
  static const int noseBridge = 6;

  /// 왼쪽 콧볼
  static const int noseLeftAlar = 129;

  /// 오른쪽 콧볼
  static const int noseRightAlar = 358;

  // ===== 입 (Mouth) =====
  /// 윗입술 위쪽 중앙
  static const int upperLipTop = 13;

  /// 아랫입술 아래쪽 중앙
  static const int lowerLipBottom = 14;

  /// 입 왼쪽 끝
  static const int mouthLeft = 61;

  /// 입 오른쪽 끝
  static const int mouthRight = 291;

  /// 윗입술 아래쪽 중앙
  static const int upperLipBottom = 0;

  /// 아랫입술 위쪽 중앙
  static const int lowerLipTop = 17;

  // ===== 얼굴 윤곽 (Face Contour) =====
  /// 턱 끝
  static const int chin = 152;

  /// 이마 중앙
  static const int foreheadCenter = 10;

  /// 왼쪽 볼
  static const int leftCheek = 234;

  /// 오른쪽 볼
  static const int rightCheek = 454;

  /// 왼쪽 관자놀이
  static const int leftTemple = 127;

  /// 오른쪽 관자놀이
  static const int rightTemple = 356;

  // ===== 홍채 (Iris) - 468번부터 =====
  /// 왼쪽 홍채 중심
  static const int leftIrisCenter = 468;

  /// 오른쪽 홍채 중심
  static const int rightIrisCenter = 473;

  /// 왼쪽 홍채 위
  static const int leftIrisTop = 469;

  /// 왼쪽 홍채 아래
  static const int leftIrisBottom = 471;

  /// 왼쪽 홍채 왼쪽
  static const int leftIrisLeft = 470;

  /// 왼쪽 홍채 오른쪽
  static const int leftIrisRight = 472;

  /// 오른쪽 홍채 위
  static const int rightIrisTop = 474;

  /// 오른쪽 홍채 아래
  static const int rightIrisBottom = 476;

  /// 오른쪽 홍채 왼쪽
  static const int rightIrisLeft = 477;

  /// 오른쪽 홍채 오른쪽
  static const int rightIrisRight = 475;

  // ===== 유용한 그룹 =====

  /// 왼쪽 눈 윤곽 인덱스들
  static const List<int> leftEyeContour = [
    33,
    7,
    163,
    144,
    145,
    153,
    154,
    155,
    133,
    173,
    157,
    158,
    159,
    160,
    161,
    246,
  ];

  /// 오른쪽 눈 윤곽 인덱스들
  static const List<int> rightEyeContour = [
    362,
    382,
    381,
    380,
    374,
    373,
    390,
    249,
    263,
    466,
    388,
    387,
    386,
    385,
    384,
    398,
  ];

  /// 입술 바깥 윤곽 인덱스들
  static const List<int> lipsOuterContour = [
    61,
    146,
    91,
    181,
    84,
    17,
    314,
    405,
    321,
    375,
    291,
    409,
    270,
    269,
    267,
    0,
    37,
    39,
    40,
    185,
  ];

  /// 얼굴 윤곽 인덱스들
  static const List<int> faceOval = [
    10,
    338,
    297,
    332,
    284,
    251,
    389,
    356,
    454,
    323,
    361,
    288,
    397,
    365,
    379,
    378,
    400,
    377,
    152,
    148,
    176,
    149,
    150,
    136,
    172,
    58,
    132,
    93,
    234,
    127,
    162,
    21,
    54,
    103,
    67,
    109,
  ];
}
