import 'package:flutter_test/flutter_test.dart';
import 'package:kwon_mediapipe_landmarker/kwon_mediapipe_landmarker.dart';
import 'package:kwon_mediapipe_landmarker/kwon_mediapipe_landmarker_platform_interface.dart';
import 'package:kwon_mediapipe_landmarker/kwon_mediapipe_landmarker_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockKwonMediapipeLandmarkerPlatform
    with MockPlatformInterfaceMixin
    implements KwonMediapipeLandmarkerPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final KwonMediapipeLandmarkerPlatform initialPlatform = KwonMediapipeLandmarkerPlatform.instance;

  test('$MethodChannelKwonMediapipeLandmarker is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelKwonMediapipeLandmarker>());
  });

  test('getPlatformVersion', () async {
    KwonMediapipeLandmarker kwonMediapipeLandmarkerPlugin = KwonMediapipeLandmarker();
    MockKwonMediapipeLandmarkerPlatform fakePlatform = MockKwonMediapipeLandmarkerPlatform();
    KwonMediapipeLandmarkerPlatform.instance = fakePlatform;

    expect(await kwonMediapipeLandmarkerPlugin.getPlatformVersion(), '42');
  });
}
