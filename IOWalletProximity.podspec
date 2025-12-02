#
#  Be sure to run `pod spec lint libIso18013.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  spec.name         = "IOWalletProximity"
  spec.version      = "1.3.0"
  spec.summary      = "ISO 18013 sets global standards for driving licenses, covering both physical cards and mobile formats."

  spec.description  = <<-DESC
                  ISO 18013 is an international standard that defines the specifications for driving license cards, particularly focusing on their physical and digital formats. It ensures interoperability and security, making it easier for licenses to be recognized across borders. It covers aspects like the layout, data encoding, and features necessary for both physical cards and mobile driving licenses (mDLs), ensuring global consistency in the way driving credentials are handled.
                   DESC

  spec.homepage     = "https://github.com/pagopa/iso18013-ios"

  spec.license      = { :type => "MIT", :file => "LICENSE" }

  spec.authors = [
    "acapadev",
    "MartinaDurso95"
  ]

  spec.ios.deployment_target = '13.0'

  spec.source                  = { :http => "https://github.com/pagopa/iso18013-ios/releases/download/" + spec.version.to_s + "/IOWalletProximity-" + spec.version.to_s + ".xcframework.zip" }
  spec.ios.vendored_frameworks = "IOWalletProximity.xcframework"


  spec.pod_target_xcconfig = { 
    'SWIFT_INCLUDE_PATHS' => '$(inherited) ${PODS_BUILD_DIR}/$(CONFIGURATION)$(EFFECTIVE_PLATFORM_NAME)',
    'ENABLE_USER_SCRIPT_SANDBOXING' => 'NO'
  }

end
