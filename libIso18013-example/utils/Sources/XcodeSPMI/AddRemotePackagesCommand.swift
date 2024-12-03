//
//  AddRemotePackagesCommand.swift
//  libraries
//
//  Created by Antonio on 14/10/24.
//

import XcodeProj
import PathKit
import ArgumentParser
import Foundation


struct AddRemotePackagesCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "addRemotePackages",
        abstract: "Injects remote SPM Packages"
    )
    
    @Option(help: "The Pod project directory.")
    var projectPath: String
    
    @Option(help: "The config json path")
    var configPath: String
    
    @Option(help: "The target to be configured with that dependency")
    var targetName: String
    
    func run() throws {
        
       
        let projectPath = Path(projectPath)
        let xcodeproject = try XcodeProj(path: projectPath)
       
        guard let config = readConfig(configPathStr: configPath) else {
            throw MyError.runtimeError("config file not found")
            return
        }
        
        config.packages.forEach({
            package in
            try! applyPackageConfig(xcodeproject: xcodeproject, packageConfig: package)
        })
        
        try xcodeproject.write(path: projectPath)
    }
    
    private func applyPackageConfig(xcodeproject: XcodeProj, packageConfig: AddRemotePackagesConfigPackage) throws {
        let pbxproj = xcodeproject.pbxproj
        let project = pbxproj.projects.first
        let versionReq: XCRemoteSwiftPackageReference.VersionRequirement
        
        if packageConfig.versionKind == "branch" {
            versionReq = XCRemoteSwiftPackageReference.VersionRequirement.branch(packageConfig.versionValue)
        } else if packageConfig.versionKind == "uptomaj" {
            versionReq = XCRemoteSwiftPackageReference.VersionRequirement.upToNextMajorVersion(packageConfig.versionValue)
        }
        else {
            versionReq = XCRemoteSwiftPackageReference.VersionRequirement.exact(packageConfig.versionValue)
        }
        
        
        _ = try project?.addSwiftPackage(repositoryURL: packageConfig.spmUrl, productName: packageConfig.product, versionRequirement: versionReq, targetName: targetName)
    }
    
    private func readConfig(configPathStr: String) -> AddRemotePackagesConfig? {
        let configPath = Path(configPathStr)
        
        guard let configData = try? configPath.read() else {
            return nil
        }
        
        guard let config = try? JSONDecoder().decode(AddRemotePackagesConfig.self, from: configData) else {
            return nil
        }
        
        return config
    }
}

class AddRemotePackagesConfig : Codable {
    var packages: [AddRemotePackagesConfigPackage]
    
    init(packages: [AddRemotePackagesConfigPackage]) {
        self.packages = packages
    }
}

class AddRemotePackagesConfigPackage : Codable {
    var spmUrl: String
    var product: String
    var versionKind: String
    var versionValue: String
    
    init(spmUrl: String, product: String, versionKind: String, versionValue: String) {
        self.spmUrl = spmUrl
        self.product = product
        self.versionKind = versionKind
        self.versionValue = versionValue
    }
}

        enum MyError: Error {
        case runtimeError(String)
        }
