#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint omicallsdk.podspec` to validate before publishing.
#

Pod::Spec.new do |s|
  s.name             = 'omikit'
  s.version          = '0.0.5'
  s.summary          = 'Omikit Flutter Plugin'
  s.description      = <<-DESC
Omikit plugin for flutter.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Stringee' => 'info@stringee.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'

  s.dependency 'Flutter'
  s.dependency 'OmiKit', '~> 1.0.7'
  s.static_framework = true

  s.ios.deployment_target = '13.0'
end