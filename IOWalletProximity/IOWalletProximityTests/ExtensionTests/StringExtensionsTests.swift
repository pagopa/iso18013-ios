//
//  StringExtensionsTests.swift
//  libIso18013
//
//  Created by Martina D'urso on 18/10/24.
//


import XCTest
internal import SwiftCBOR
@testable import IOWalletProximity

class StringExtensionsTests: XCTestCase {
    
    func testFullDateEncoded() {
        let dateString = "2023-10-18"
        let cbor = dateString.fullDateEncoded
        
        if case let .tagged(tag, value) = cbor {
            XCTAssertEqual(tag.rawValue, 1004, "Tag should be 1004 for full date encoding")
            XCTAssertEqual(value, .utf8String(dateString), "CBOR value should be the date string")
        } else {
            XCTFail("Failed to encode date string as tagged CBOR value")
        }
    }
    
    func testToPosixDateISOFormat() {
        let dateString = "2023-10-18T15:45:00"
        let formattedDate = dateString.toPosixDate()
        XCTAssertEqual(formattedDate, "2023-10-18", "Date should be formatted in ISO format")
    }
    
    func testToPosixDateMMDDYYYYFormat() {
        let dateString = "2023-10-18T15:45:00"
        let formattedDate = dateString.toPosixDate(useIsoFormat: false)
        XCTAssertEqual(formattedDate, "10/18/2023", "Date should be formatted in MM/DD/YYYY format")
    }
    
    func testBase64URLEscaped() {
        let base64String = "a+b/c="
        let escapedString = base64String.base64URLEscaped()
        XCTAssertEqual(escapedString, "a-b_c", "Base64 URL escaped string should replace +, /, and =")
    }
    
    func testHexDecimal() {
        let hexString = "1A"
        let decimalValue = hexString.hex_decimal
        XCTAssertEqual(decimalValue, 26, "Hex string should be correctly converted to decimal value")
    }
    
    func testSubscriptClosedRange() {
        let string = "Hello, World!"
        let substring = string[7...11]
        XCTAssertEqual(substring, "World", "Subscript with closed range should return the correct substring")
    }
    
    func testSubscriptRange() {
        let string = "Hello, World!"
        let substring = string[7..<12]
        XCTAssertEqual(substring, "World", "Subscript with range should return the correct substring")
    }
    
    func testByteArray() {
        let hexString = "1A2B3C"
        let byteArray = hexString.byteArray
        XCTAssertEqual(byteArray, [26, 43, 60], "Hex string should be correctly converted to byte array")
    }
    
    func testToBytesValidHex() {
        let hexString = "1A2B3C"
        let bytes = hexString.toBytes()
        XCTAssertNotNil(bytes, "Valid hex string should return non-nil byte array")
        XCTAssertEqual(bytes, [26, 43, 60], "Hex string should be correctly converted to byte array")
    }
    
    func testToBytesInvalidHex() {
        let hexString = "1A2B3"
        let bytes = hexString.toBytes()
        XCTAssertNil(bytes, "Invalid hex string should return nil")
    }
}
