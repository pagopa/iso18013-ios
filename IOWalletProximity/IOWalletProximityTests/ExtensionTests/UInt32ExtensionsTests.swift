//
//  UInt32ExtensionsTests.swift
//  libIso18013
//
//  Created by Martina D'urso on 18/10/24.
//


import XCTest
@testable import libIso18013

class UInt32ExtensionsTests: XCTestCase {
    func testDataConversion() {
        let value: UInt32 = 0x12345678
        let data = value.data
        
        let expectedData = Data([0x78, 0x56, 0x34, 0x12])
        XCTAssertEqual(data, expectedData, "Data conversion did not match expected result")
    }
    
    func testByteArrayLittleEndian() {
        let value: UInt32 = 0x12345678
        let byteArray = value.byteArrayLittleEndian
        
        let expectedByteArray: [UInt8] = [0x12, 0x34, 0x56, 0x78]
        XCTAssertEqual(byteArray, expectedByteArray, "Byte array (little endian) did not match expected result")
    }
}
