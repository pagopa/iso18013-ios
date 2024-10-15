def integrate_spms(projects, spm)
  projects.each do |project|
    puts "Injecting #{spm} framework into #{project}"
    puts "Current directory : #{Dir.pwd}"
    `/usr/bin/xcrun --sdk macosx swift run --package-path libIso18013/libraries XcodeSPMI addRemotePackages --project-path Pods.xcodeproj --config-path #{spm} --target-name #{project}`
  end
end

projects = ["libIso18013"]
integrate_spms(projects, "libIso18013/tools/config.json")
