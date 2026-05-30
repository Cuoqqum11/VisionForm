import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kwon_mediapipe_landmarker/kwon_mediapipe_landmarker_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelKwonMediapipeLandmarker platform = MethodChannelKwonMediapipeLandmarker();
  const MethodChannel channel = MethodChannel('kwon_mediapipe_landmarker');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
