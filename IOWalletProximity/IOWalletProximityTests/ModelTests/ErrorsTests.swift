//
//  ErrorsTests.swift
//  libIso18013
//
//  Created by Martina D'urso on 30/10/24.
//


import XCTest
internal import SwiftCBOR
internal import OrderedCollections

@testable import IOWalletProximity

class ErrorsTests: XCTestCase {
    func testErrors_EncodingAndDecoding_ShouldReturnEquivalentObject() {
        let originalErrors: [String: ErrorItems] = [
            "NamespaceA": ["ErrorA": 100, "ErrorB": 200],
            "NamespaceB": ["ErrorC": 300]
        ]
        let errors = Errors(errors: originalErrors)
        
        let encodedCBOR = errors.toCBOR(options: CBOROptions())
        guard let decodedErrors = Errors(cbor: encodedCBOR) else {
            XCTFail("Failed to decode CBOR into Errors")
            return
        }
        
        XCTAssertEqual(decodedErrors.errors, originalErrors, "Decoded Errors does not match the original")
    }

    func testErrors_WhenCBORIsInvalid_ShouldReturnNil() {
        let invalidCBOR: CBOR = .array([.utf8String("Invalid"), .unsignedInt(123)])
        
        let errors = Errors(cbor: invalidCBOR)
        
        XCTAssertNil(errors, "Expected nil for invalid CBOR, but got an Errors instance")
    }

    func testErrors_WhenEmptyCBORMap_ShouldReturnNil() {
        let emptyCBOR: CBOR = .map([:])
        
        let errors = Errors(cbor: emptyCBOR)
        
        XCTAssertNil(errors, "Expected nil for empty CBOR map, but got an Errors instance")
    }
}
