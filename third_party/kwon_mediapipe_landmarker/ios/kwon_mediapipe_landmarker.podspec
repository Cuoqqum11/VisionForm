#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint kwon_mediapipe_landmarker.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'kwon_mediapipe_landmarker'
  s.version          = '0.0.1'
  s.summary          = 'Flutter plugin for MediaPipe Face and Pose Landmarker'
  s.description      = <<-DESC
Flutter plugin for MediaPipe Face and Pose Landmarker.
Real-time facial expression, eye contact, and posture analysis.
                       DESC
  s.homepage         = 'https://github.com/your-username/kwon_mediapipe_landmarker'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Kwon Taewan' => 'your-email@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '14.0'

  # MediaPipe Tasks Vision
  s.dependency 'MediaPipeTasksVision', '~> 0.10.14'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # 모델 파일을 리소스로 포함
  s.resources = ['Assets/**/*']
end
