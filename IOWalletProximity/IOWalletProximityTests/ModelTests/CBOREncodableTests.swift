//
//  Untitled.swift
//  libIso18013
//
//  Created by Martina D'urso on 03/10/24.
//

import XCTest
internal import SwiftCBOR
@testable import IOWalletProximity

// Dummy type conforming to CBOREncodable for testing purposes
struct TestEncodable: CBOREncodable {
    var value: Int
    
    // Mocking the toCBOR function
    func toCBOR(options: CBOROptions) -> CBOR {
        return .unsignedInt(UInt64(Int64(value)))
    }
}

final class CBOREncodableTests: XCTestCase {
    
    func testEncodeFunction() {
        // Arrange
        let testObject = TestEncodable(value: 42)
        let options = CBOROptions()
        
        // Act
        let encodedResult = testObject.encode(options: options)
        
        // Assert
        XCTAssertNotNil(encodedResult, "Encoded result should not be nil")
        XCTAssertEqual(try? CBOR.decode(encodedResult), CBOR.unsignedInt(UInt64(Int64(42))), "Encoded result should correctly represent the value")
    }
    
    func testTaggedEncodedProperty() {
        // Arrange
        let testObject = TestEncodable(value: 42)
        
        // Act
        let taggedResult = testObject.taggedEncoded
        
        // Assert
        if case let CBOR.tagged(tag, value) = taggedResult {
            XCTAssertEqual(tag, .encodedCBORDataItem, "Tag should be encodedCBORDataItem")
            XCTAssertEqual(value, .byteString(CBOR.encode(testObject)), "Tagged result should correctly encode the object")
        } else {
            XCTFail("Tagged result is not a tagged CBOR value")
        }
    }
    
}
