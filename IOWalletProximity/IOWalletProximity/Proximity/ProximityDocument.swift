//
//  ProximityDocument.swift
//  IOWalletProximity
//
//  Created by Antonio Caparello on 01/04/25.
//


import Foundation

public class ProximityDocument {
    public var docType: String
    
    public var issuerSigned: [UInt8]
    internal var deviceKey: CoseKeyPrivate
    
    public convenience init?(docType: String, issuerSigned: [UInt8], deviceKeyRaw: [UInt8]) {
        guard let deviceKey = CoseKeyPrivate.init(data: deviceKeyRaw) else {
            return nil
        }
        
        self.init(docType: docType, issuerSigned: issuerSigned, deviceKey: deviceKey)
    }
    
    public convenience init?(docType: String, issuerSigned: [UInt8], deviceKeySecKey: SecKey) {
        guard let deviceKey = CoseKeyPrivate.init(crv: .p256, secKey: deviceKeySecKey) else {
            return nil
        }
        
        self.init(docType: docType, issuerSigned: issuerSigned, deviceKey: deviceKey)
    }
    
    public convenience init?(docType: String, issuerSigned: [UInt8], deviceKeyTag: String) {
        guard let deviceKey = CoseKeyPrivate.init(crv: .p256, keyTag: deviceKeyTag) else {
            return nil
        }
        
        self.init(docType: docType, issuerSigned: issuerSigned, deviceKey: deviceKey)
    }
    
    private init(docType: String, issuerSigned: [UInt8], deviceKey: CoseKeyPrivate) {
        self.docType = docType
        self.issuerSigned = issuerSigned
        self.deviceKey = deviceKey
    }
}
