
def integrate_spms(projects, spms)
    projects.each do |project|
      spms.each do |spm|
        puts "Injecting #{spm} framework into #{project}"
        puts "Current directory : #{Dir.pwd}"
        `/usr/bin/xcrun --sdk macosx swift run --package-path libIso18013/libraries XcodeSPMI addRemote --project-path Pods.xcodeproj --spm-url #{spm} --target-name #{project}`
        end
    end
  end


projects = ["libIso18013"]
spms = ["https://github.com/niscy-eudiw/SwiftCBOR.git --product SwiftCBOR --version-kind exact --version-value 0.5.7", "https://github.com/kishikawakatsumi/KeychainAccess.git --product KeychainAccess --version-kind uptomaj --version-value 4.2.2"]
integrate_spms(projects, spms)
