//
//  LibIso18013UtilsTests.swift
//  libIso18013
//
//  Created by Antonio on 11/10/24.
//


import XCTest
import SwiftCBOR
@testable import libIso18013

final class LibIso18013UtilsTests: XCTestCase {
    
    func testDecodeDocument() {
        do {
            let document = try LibIso18013Utils.shared.decodeDocument(base64Encoded: DocumentTestData.document1)
            assert(document.docType == DocType.euPid.rawValue)
        }
        catch {
            print(error.localizedDescription)
            assert(false)
        }
    }
    
    func testDecodeDeviceDocument() {
        do {
            let document = try LibIso18013Utils.shared.decodeDeviceDocument(
                documentBase64Encoded: DocumentTestData.document1,
                privateKeyBase64Encoded: DocumentTestData.devicePrivateKey)
            
            assert(document.docType == DocType.euPid.rawValue)
        }
        catch {
            print(error.localizedDescription)
            assert(false)
        }
    }
    
    func testDecodeDeviceDocumentWrongKey() {
        do {
            let wrongKey = try LibIso18013Utils.shared.createSecurePrivateKey()
           
            assert(true)
            
            let _ = try LibIso18013Utils.shared.decodeDeviceDocument(
                documentBase64Encoded: DocumentTestData.document1,
                privateKeyBase64Encoded: wrongKey.base64Encoded(options: CBOROptions()))
            
            assert(false)
        }
        catch {
            print(error.localizedDescription)
            assert(true)
        }
    }
}
