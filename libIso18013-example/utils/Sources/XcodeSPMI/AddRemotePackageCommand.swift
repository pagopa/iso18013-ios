import XcodeProj
import PathKit
import ArgumentParser

struct AddRemotePackageCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "addRemote",
        abstract: "Injects a remote SPM Package"
    )
    
    @Option(help: "The Pod project directory.")
    var projectPath: String

    @Option(help: "The SwiftPM package URL.")
    var spmURL: String

    @Option(help: "The product from that package to be injected.")
    var product: String

    @Option(help: "The package version kind to be injected.")
    var versionKind: String

    @Option(help: "The package version value to be injected.")
    var versionValue: String

    @Option(help: "The target to be configured with that dependency")
    var targetName: String

    func run() throws {
        let projectPath = Path(projectPath)
        let xcodeproject = try XcodeProj(path: projectPath)
        let pbxproj = xcodeproject.pbxproj
        let project = pbxproj.projects.first
        let versionReq: XCRemoteSwiftPackageReference.VersionRequirement

        if versionKind == "branch" {
            versionReq = XCRemoteSwiftPackageReference.VersionRequirement.branch(versionValue)
        } else if versionKind == "uptomaj" {
            versionReq = XCRemoteSwiftPackageReference.VersionRequirement.upToNextMajorVersion(versionValue)
        }
        else {
            versionReq = XCRemoteSwiftPackageReference.VersionRequirement.exact(versionValue)
        }


        _ = try project?.addSwiftPackage(repositoryURL: spmURL, productName: product, versionRequirement: versionReq, targetName: targetName)
        try xcodeproject.write(path: projectPath)}
}
