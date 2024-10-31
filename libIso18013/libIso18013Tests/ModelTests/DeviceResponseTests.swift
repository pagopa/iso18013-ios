//
//  DeviceResponseTests.swift
//  libIso18013
//
//  Created by Martina D'urso on 03/10/24.
//
import XCTest
import SwiftCBOR
@testable import libIso18013

class DeviceResponseTests: XCTestCase {
    
    func testInitializerWithDefaultValues() {
        let deviceResponse = DeviceResponse(status: 200)
        
        XCTAssertEqual(deviceResponse.version, DeviceResponse.defaultVersion)
        XCTAssertNil(deviceResponse.documents)
        XCTAssertNil(deviceResponse.documentErrors)
        XCTAssertEqual(deviceResponse.status, 200)
    }
    
    func testCBORDecodingInvalidData() {
        let cbor: CBOR = .map([
            .utf8String("version"): .unsignedInt(123), // Invalid type for version
            .utf8String("status"): .unsignedInt(200)
        ])
        
        let deviceResponse = DeviceResponse(cbor: cbor)
        XCTAssertNil(deviceResponse)
    }
    
    // test based on D.4.1.2 mdoc response section of the ISO/IEC FDIS 18013-5 document
    func testDecodeDeviceResponse() throws {
        let dr = try XCTUnwrap(DeviceResponse(data: AnnexdTestData.d412.bytes))
        XCTAssertEqual(dr.version, "1.0")
        let docs = try XCTUnwrap(dr.documents)
        let doc = try XCTUnwrap(docs.first)
     
    }
    
    func testEncodeDeviceResponse() throws {
        let cborIn = try XCTUnwrap(try CBOR.decode(AnnexdTestData.d412.bytes))
        let dr = try XCTUnwrap(DeviceResponse(cbor: cborIn))
        let cborDr = dr.toCBOR(options: CBOROptions())
    }
    
}
