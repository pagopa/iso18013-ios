//
//  DocumentErrorTests.swift
//  libIso18013
//
//  Created by Martina D'urso on 30/10/24.
//

import XCTest
import Security
internal import SwiftCBOR

@testable import libIso18013

class DocumentErrorTests: XCTestCase {
    func testDocumentError_EncodingAndDecoding() {
        let originalErrors: [String: UInt64] = [
            "DocTypeA": 100,
            "DocTypeB": 200
        ]
        let documentError = DocumentError(documentErrors: originalErrors)
        
        let encodedCBOR = documentError.toCBOR(options: CBOROptions())
        guard let decodedDocumentError = DocumentError(cbor: encodedCBOR) else {
            XCTFail("Failed to decode CBOR into DocumentError")
            return
        }
        
        XCTAssertEqual(decodedDocumentError.documentErrors,
                       originalErrors,
                       "Decoded DocumentError does not match the original")
    }

    func testDocumentError_CBORIsInvalid() {
        let invalidCBOR: CBOR = .array([.utf8String("Invalid"), .unsignedInt(123)])
        
        let documentError = DocumentError(cbor: invalidCBOR)
        
        XCTAssertNil(documentError, "Expected nil for invalid CBOR, but got a DocumentError instance")
    }

    func testDocumentError_EmptyCBORMap() {
        let emptyCBOR: CBOR = .map([:])
        
        let documentError = DocumentError(cbor: emptyCBOR)
        
        XCTAssertNil(documentError, "Expected nil for empty CBOR map, but got a DocumentError instance")
    }
}
