//
//  DrivingPrivilegeCodeTests.swift
//  libIso18013
//
//  Created by Martina D'urso on 18/10/24.
//

import XCTest
internal import SwiftCBOR
@testable import libIso18013

class DrivingPrivilegeCodeTests: XCTestCase {
    
    func testInitializerWithValidCode() {
        let code = "B"
        let sign = "+"
        let value = "Allowed"
        let drivingPrivilegeCode = DrivingPrivilegeCode(code: code, sign: sign, value: value)
        
        XCTAssertEqual(drivingPrivilegeCode.code, code)
        XCTAssertEqual(drivingPrivilegeCode.sign, sign)
        XCTAssertEqual(drivingPrivilegeCode.value, value)
    }
    
    func testInitializerWithNilValues() {
        let code = "B"
        let drivingPrivilegeCode = DrivingPrivilegeCode(code: code, sign: nil, value: nil)
        
        XCTAssertEqual(drivingPrivilegeCode.code, code)
        XCTAssertNil(drivingPrivilegeCode.sign)
        XCTAssertNil(drivingPrivilegeCode.value)
    }
    
    func testEquality() {
        let codeA = DrivingPrivilegeCode(code: "A", sign: nil, value: nil)
        let codeB = DrivingPrivilegeCode(code: "B", sign: nil, value: nil)
        let anotherCodeA = DrivingPrivilegeCode(code: "A", sign: nil, value: nil)
        
        XCTAssertEqual(codeA.code, anotherCodeA.code, "Codes with the same value should be equal")
        XCTAssertNotEqual(codeA.code, codeB.code, "Codes with different values should not be equal")
    }
    
    func testCBOREncoding() {
        let drivingPrivilegeCode = DrivingPrivilegeCode(code: "B", sign: "+", value: "Allowed")
        let cbor = drivingPrivilegeCode.toCBOR(options: CBOROptions())
        
        if case let .map(encodedMap) = cbor {
            XCTAssertEqual(encodedMap[.utf8String("code")], .utf8String("B"))
            XCTAssertEqual(encodedMap[.utf8String("sign")], .utf8String("+"))
            XCTAssertEqual(encodedMap[.utf8String("value")], .utf8String("Allowed"))
        } else {
            XCTFail("Failed to encode DrivingPrivilegeCode to CBOR map")
        }
    }
    
    func testCBORDecoding() {
        let cbor: CBOR = .map([
            .utf8String("code"): .utf8String("B"),
            .utf8String("sign"): .utf8String("+"),
            .utf8String("value"): .utf8String("Allowed")
        ])
        let drivingPrivilegeCode = DrivingPrivilegeCode(cbor: cbor)
        
        XCTAssertNotNil(drivingPrivilegeCode)
        XCTAssertEqual(drivingPrivilegeCode?.code, "B")
        XCTAssertEqual(drivingPrivilegeCode?.sign, "+")
        XCTAssertEqual(drivingPrivilegeCode?.value, "Allowed")
    }
    
    func testCBORDecodingWithMissingOptionalValues() {
        let cbor: CBOR = .map([
            .utf8String("code"): .utf8String("B")
        ])
        let drivingPrivilegeCode = DrivingPrivilegeCode(cbor: cbor)
        
        XCTAssertNotNil(drivingPrivilegeCode)
        XCTAssertEqual(drivingPrivilegeCode?.code, "B")
        XCTAssertNil(drivingPrivilegeCode?.sign)
        XCTAssertNil(drivingPrivilegeCode?.value)
    }
    
    func testCBORDecodingInvalidData() {
        let cbor: CBOR = .unsignedInt(123) // Invalid type for a DrivingPrivilegeCode
        let drivingPrivilegeCode = DrivingPrivilegeCode(cbor: cbor)
        
        XCTAssertNil(drivingPrivilegeCode, "DrivingPrivilegeCode should be nil for invalid CBOR data")
    }
}
