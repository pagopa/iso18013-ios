//
//  ProximityDocumentTests.swift
//  IOWalletProximity
//
//  Created by Antonio Caparello on 10/04/25.
//


import XCTest
import Security
internal import SwiftCBOR

@testable import IOWalletProximity

class ProimityDocumentTests: XCTestCase {
 
    func testConstructorWithDeviceKeyRaw() {
        
        guard let documentData: [UInt8] = Data(base64Encoded: DocumentTestData.issuerSignedDocument1)?.bytes else {
            XCTFail("document data must be valid")
            return
        }
        
        guard let deviceKeyRaw: [UInt8] = Data(base64Encoded: DocumentTestData.devicePrivateKey)?.bytes else {
            XCTFail("device key must be valid")
            return
        }
        
        guard let document = ProximityDocument(docType: DocType.euPid.rawValue, issuerSigned: documentData, deviceKeyRaw: deviceKeyRaw) else {
            XCTFail("document must be valid")
            return
        }
        
        XCTAssert(document.docType == DocType.euPid.rawValue)
        
    }
    
    func testConstructorWithNotValidIssuerSigned() {
        //DocumentTestData.issuerSignedDocument1 is stored as base64. It can't be converted to bytes like this.
        let documentData: [UInt8] = Data(DocumentTestData.issuerSignedDocument1.utf8).bytes
        
        guard let deviceKeyRaw: [UInt8] = Data(base64Encoded: DocumentTestData.devicePrivateKey)?.bytes else {
            XCTFail("device key must be valid")
            return
        }
        
        let document = ProximityDocument(docType: DocType.euPid.rawValue, issuerSigned: documentData, deviceKeyRaw: deviceKeyRaw)
        
        if document != nil {
            XCTFail("document must not be valid")
        }
        
    }
    
    
    
    
}
