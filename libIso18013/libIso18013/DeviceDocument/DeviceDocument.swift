//
//  DeviceDocument.swift
//  libIso18013
//
//  Created by Antonio on 04/10/24.
//

import SwiftCBOR

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

extension DeviceDocument : CBOREncodable {
    public func toCBOR(options: SwiftCBOR.CBOROptions) -> SwiftCBOR.CBOR {
        
        let documentValue: CBOR = document == nil ?
            .null :
            .byteString(document!.encode(options: CBOROptions()))
        
        let cbor: CBOR = [
            -1: .utf8String(state.rawValue),
             -2: .date(createdAt),
             -3: .byteString(deviceKey.encode(options: options)),
             -4: .utf8String(docType),
             -5: .utf8String(name),
             -6: .utf8String(identifier),
             -7: documentValue
        ]
        return cbor
    }
}

extension DeviceDocument : CBORDecodable {
    public init?(cbor: SwiftCBOR.CBOR) {
        guard let stateCBOR = cbor[-1],
              let createdAtCBOR = cbor[-2],
              let deviceKeyCBOR = cbor[-3],
              let docTypeCBOR = cbor[-4],
              let nameCBOR = cbor[-5],
              let identifierCBOR = cbor[-6],
              let documentCBOR = cbor[-7] else {
            return nil
        }
        
        guard case let CBOR.utf8String(stateValue) = stateCBOR,
              case let CBOR.date(createdAtValue) = createdAtCBOR,
              case let CBOR.byteString(deviceKeyValue) = deviceKeyCBOR,
              case let CBOR.utf8String(docTypeValue) = docTypeCBOR,
              case let CBOR.utf8String(nameValue) = nameCBOR,
              case let CBOR.utf8String(identifierValue) = identifierCBOR
        else {
            return nil
        }
        
        guard let state = DeviceDocumentState(rawValue: stateValue) else {
            return nil
        }
        
        guard let deviceKey = CoseKeyPrivate(data: deviceKeyValue) else {
            return nil
        }
        
        
        
        if case let CBOR.byteString(documentValue) = documentCBOR {
            guard let document = Document(data: documentValue) else {
                return nil
            }
            self.document = document
        }
        else if case CBOR.null = documentCBOR {
            self.document = nil
        }
        else {
            return nil
        }
        
        self.state = state
        self.createdAt = createdAtValue
        self.docType = docTypeValue
        self.name = nameValue
        self.identifier = identifierValue
        self.deviceKey = deviceKey
    }
    
    
}

public enum DocType : String {
    case euPid = "eu.europa.ec.eudi.pid.1"
    case mDL = "org.iso.18013.5.1.mDL"
}

public enum DeviceDocumentState : String {
    case unsigned = "UNSIGNED"
    case deferred = "DEFERRED"
    case issued = "ISSUED"
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
