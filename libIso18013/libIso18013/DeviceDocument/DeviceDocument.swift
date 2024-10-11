//
//  DeviceDocument.swift
//  libIso18013
//
//  Created by Antonio on 04/10/24.
//

public struct DeviceDocument : DeviceDocumentProtocol {
    public let state: DeviceDocumentState
    public let createdAt: Date
    public let deviceKey: CoseKeyPrivate
    
    public let docType: String
    public let name: String
    
    
    public let identifier: String
    public let document: Document?
    
    public func issued(document: Document) -> DeviceDocument {
        return DeviceDocument(state: .issued, createdAt: self.createdAt, deviceKey: self.deviceKey, docType: self.docType, name: self.name, identifier: self.identifier, document: document)
    }
    
    public func coseSign(payloadData: Data, alg: Cose.VerifyAlgorithm) throws-> Cose {
        return try Cose.makeCoseSign1(payloadData: payloadData, deviceKey: deviceKey, alg: alg)
    }
}

public enum DocType : String {
    case euPid = "eu.europa.ec.eudi.pid.1"
    case mDL = "org.iso.18013.5.1.mDL"
}

public enum DeviceDocumentState {
    case unsigned
    case deferred
    case issued
}

public protocol DeviceDocumentProtocol {
    var identifier: String { get }
    var state: DeviceDocumentState { get }
    var createdAt: Date { get }
    
    var document: Document? { get }
    var deviceKey: CoseKeyPrivate { get }
    
    //DA CAPIRE
    var docType: String { get }
    var name: String { get }
    
}
