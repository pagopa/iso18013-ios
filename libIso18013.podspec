#
#  Be sure to run `pod spec lint libIso18013.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  spec.name         = "libIso18013"
  spec.version      = "0.0.1"
  spec.summary      = "ISO 18013 sets global standards for driving licenses, covering both physical cards and mobile formats."

  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  spec.description  = <<-DESC
                  ISO 18013 is an international standard that defines the specifications for driving license cards, particularly focusing on their physical and digital formats. It ensures interoperability and security, making it easier for licenses to be recognized across borders. It covers aspects like the layout, data encoding, and features necessary for both physical cards and mobile driving licenses (mDLs), ensuring global consistency in the way driving credentials are handled.
                   DESC

  spec.homepage     = "https://github.com/pagopa/iso18013-ios"

  spec.license      = { :type => "MIT", :file => "LICENSE" }


  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the authors of the library, with email addresses. Email addresses
  #  of the authors are extracted from the SCM log. E.g. $ git log. CocoaPods also
  #  accepts just a name if you'd rather not provide an email address.
  #
  #  Specify a social_media_url where others can refer to, for example a twitter
  #  profile URL.
  #

  spec.authors = [
    "acapadev",
    "MartinaDurso95"
  ]

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If this Pod runs only on iOS or OS X, then specify the platform and
  #  the deployment target. You can optionally include the target after the platform.
  #

  # spec.platform     = :ios
  # spec.platform     = :ios, "16.0"

  #  When using multiple platforms
  # spec.ios.deployment_target = "16.0"
  # spec.osx.deployment_target = "10.7"
  # spec.watchos.deployment_target = "2.0"
  # spec.tvos.deployment_target = "9.0"
  # spec.visionos.deployment_target = "1.0"

  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the location from where the source should be retrieved.
  #  Supports git, hg, bzr, svn and HTTP.
  #

  spec.ios.deployment_target = '16.0'

  spec.source       = { :git => "https://github.com/pagopa/iso18013-ios.git", :tag => "#{spec.version}" }


  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  CocoaPods is smart about how it includes source code. For source files
  #  giving a folder will include any swift, h, m, mm, c & cpp files.
  #  For header files it will include any header in the folder.
  #  Not including the public_header_files will make all headers public.
  #

  # Include all source files, but exclude test files
  spec.source_files = 'libIso18013/**/*.{swift,h,m}', 'tools.zip'
  spec.exclude_files = 'libIso18013/libIso18013Tests/**/*'

  spec.pod_target_xcconfig = { 
    'SWIFT_INCLUDE_PATHS' => '$(inherited) ${PODS_BUILD_DIR}/$(CONFIGURATION)$(EFFECTIVE_PLATFORM_NAME)',
    'ENABLE_USER_SCRIPT_SANDBOXING' => 'NO'
  }

  spec.script_phase = [
    {
      :name => 'Inject SPM', :script => 'if [ -f libIso18013/tools.zip ] ; then unzip -o libIso18013/tools.zip -d libIso18013/ && unzip -o libIso18013/tools/libraries.zip -d libIso18013/ && rm -f libIso18013/tools.zip && touch libIso18013/installed.txt &&  ruby libIso18013/tools/prepare.rb ;else echo "SPM Already Injected" ; fi', :execution_position => :before_compile, :output_files => ['Pods/libIso18013/installed.txt']
    }
  ]

end
