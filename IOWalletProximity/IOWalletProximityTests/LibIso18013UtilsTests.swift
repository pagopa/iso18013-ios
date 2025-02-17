//
//  LibIso18013UtilsTests.swift
//  libIso18013
//
//  Created by Antonio on 11/10/24.
//


import XCTest
internal import SwiftCBOR
@testable import libIso18013

final class LibIso18013UtilsTests: XCTestCase {
    
    func testDecodeDocument() {
        do {
            let document = try LibIso18013Utils.shared.decodeDocument(base64Encoded: DocumentTestData.document1)
            XCTAssert(document.docType == DocType.euPid.rawValue)
        }
        catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testDecodeDeviceDocument() {
        do {
            let document = try LibIso18013Utils.shared.decodeDeviceDocument(
                documentBase64Encoded: DocumentTestData.document1,
                privateKeyBase64Encoded: DocumentTestData.devicePrivateKey)
            
            XCTAssert(document.docType == DocType.euPid.rawValue)
        }
        catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testDecodeDeviceDocumentWrongKey() {
        do {
            let wrongKey = try LibIso18013Utils.shared.createSecurePrivateKey()
           
            XCTAssert(true)
            
            let _ = try LibIso18013Utils.shared.decodeDeviceDocument(
                documentBase64Encoded: DocumentTestData.document1,
                privateKeyBase64Encoded: wrongKey.base64Encoded(options: CBOROptions()))
            
            XCTFail("must throw an error")
        }
        catch {
            print(error.localizedDescription)
            XCTAssert(true)
        }
    }
}
