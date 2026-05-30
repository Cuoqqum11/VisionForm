/// Pose 랜드마크 인덱스 (0-32, 총 33개)
class PoseLandmarkIndex {
  // 얼굴 (0-10)
  static const int nose = 0;
  static const int leftEyeInner = 1;
  static const int leftEye = 2;
  static const int leftEyeOuter = 3;
  static const int rightEyeInner = 4;
  static const int rightEye = 5;
  static const int rightEyeOuter = 6;
  static const int leftEar = 7;
  static const int rightEar = 8;
  static const int mouthLeft = 9;
  static const int mouthRight = 10;
  
  // 상체 (11-22)
  static const int leftShoulder = 11;
  static const int rightShoulder = 12;
  static const int leftElbow = 13;
  static const int rightElbow = 14;
  static const int leftWrist = 15;
  static const int rightWrist = 16;
  static const int leftPinky = 17;
  static const int rightPinky = 18;
  static const int leftIndex = 19;
  static const int rightIndex = 20;
  static const int leftThumb = 21;
  static const int rightThumb = 22;
  
  // 하체 (23-32)
  static const int leftHip = 23;
  static const int rightHip = 24;
  static const int leftKnee = 25;
  static const int rightKnee = 26;
  static const int leftAnkle = 27;
  static const int rightAnkle = 28;
  static const int leftHeel = 29;
  static const int rightHeel = 30;
  static const int leftFootIndex = 31;
  static const int rightFootIndex = 32;
  
  /// 총 랜드마크 개수
  static const int count = 33;
  
  /// 랜드마크 이름 목록
  static const List<String> names = [
    'nose',
    'leftEyeInner', 'leftEye', 'leftEyeOuter',
    'rightEyeInner', 'rightEye', 'rightEyeOuter',
    'leftEar', 'rightEar',
    'mouthLeft', 'mouthRight',
    'leftShoulder', 'rightShoulder',
    'leftElbow', 'rightElbow',
    'leftWrist', 'rightWrist',
    'leftPinky', 'rightPinky',
    'leftIndex', 'rightIndex',
    'leftThumb', 'rightThumb',
    'leftHip', 'rightHip',
    'leftKnee', 'rightKnee',
    'leftAnkle', 'rightAnkle',
    'leftHeel', 'rightHeel',
    'leftFootIndex', 'rightFootIndex',
  ];
  
  /// 인덱스로 이름 가져오기
  static String getName(int index) {
    if (index < 0 || index >= names.length) return 'unknown';
    return names[index];
  }
}
