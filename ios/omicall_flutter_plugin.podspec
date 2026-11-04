#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint omikit.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'omicall_flutter_plugin'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter project.'
  s.description      = <<-DESC
A new Flutter project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.public_header_files = 'Classes/*.h'
  s.ios.deployment_target = '13.0'
  # OmiKit is vendored (no CocoaPods Trunk dependency; Trunk goes read-only 2026-12-02).
  # Vendored version: 1.12.3. Keep ios/omicall_flutter_plugin/Package.swift (SPM) in sync.
  # Update with: scripts/update-omikit.sh <version>
  s.vendored_frameworks = 'Frameworks/OmiKit.xcframework'
  s.preserve_paths = 'Frameworks/OmiKit.xcframework'
  s.libraries = 'stdc++'
  s.frameworks = 'CoreFoundation', 'VideoToolbox', 'AudioToolbox', 'AVFoundation', 'GLKit', 'CFNetwork', 'CoreMedia'
  s.dependency 'Flutter'
  s.static_framework = true
  # xcframework only has an arm64 simulator slice.
  # SWIFT_STRICT_CONCURRENCY/warning flags carried over from OmiKit.podspec
  # (prevents dispatch_assert_queue_fail crashes under Swift 6).
  s.pod_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'x86_64',
    'OTHER_LDFLAGS' => '-ObjC',
    'SWIFT_STRICT_CONCURRENCY' => 'minimal'
  }
  s.user_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'x86_64',
    'GCC_WARN_ABOUT_MISSING_PROTOTYPES' => 'NO',
    'CLANG_WARN_STRICT_PROTOTYPES' => 'NO',
    'SWIFT_STRICT_CONCURRENCY' => 'minimal'
  }
  # s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
  # s.swift_version = '5.0'
end
