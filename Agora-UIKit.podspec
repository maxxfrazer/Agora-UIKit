#
# Be sure to run `pod lib lint Agora-UIKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Agora-UIKit'
  s.version          = '0.1.0'
  s.summary          = 'Agora video session UIKit template.'

  s.description      = <<-DESC
Use this Pod to create a video UIKit view that can be easily added to your application.
                       DESC

  s.homepage         = 'https://github.com/maxxfrazer/Agora-UIKit'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Max Cobb' => 'max@agora.io' }
  s.source           = { :git => 'https://github.com/maxxfrazer/Agora-UIKit.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'

  s.source_files = 'Sources/Agora-UIKit/*'
  
  s.dependency 'AgoraRtcEngine_iOS', '~> 3.1'
end
