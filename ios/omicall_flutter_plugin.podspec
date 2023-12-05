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
  s.ios.deployment_target = '11.0'
  s.dependency 'OmiKit', '1.6.34'
  s.dependency 'Flutter'
  s.static_framework = true
  # s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
  # s.swift_version = '5.0'
end
