//
//  DeviceEngagementTests.swift
//  libIso18013
//
//  Created by Martina D'urso on 17/10/24.
//

import XCTest
@testable import libIso18013

final class DeviceEngagementTests: XCTestCase {
    
    // Test decoding of DeviceEngagement from CBOR data
    func testDecodeDE1() throws {
        // Attempt to decode DeviceEngagement from test data and verify it's not nil
        let de = try XCTUnwrap(DeviceEngagement(data: AnnexdTestData.d31.bytes))
        // Verify the version is "1.0"
        XCTAssertEqual(de.version, "1.0")
        // Verify the first device retrieval method is BLE with specific properties
        XCTAssertEqual(de.deviceRetrievalMethods?.first, .ble(isBleServer: false, uuid: "45EFEF742B2C4837A9A3B0E1D05A6917"))
    }
    
    // Test encoding of DeviceEngagement to CBOR data
    func testEncodeDE() throws {
        // Attempt to decode DeviceEngagement from test data and verify it's not nil
        let de1 = try XCTUnwrap(DeviceEngagement(data: OtherTestData.deOnline.bytes))
        // Encode the DeviceEngagement and verify the resulting data is not nil
        let de1data = de1.encode(options: .init())
        XCTAssertNotNil(de1data)
    }
    
    // Test generation of QR code payload for BLE engagement
    func testGenerateBLEengageQRCodePayload() throws {
        // Create a DeviceEngagement in BLE server mode
        var de = DeviceEngagement(isBleServer: true)
        // Verify that the generated QR code payload is not nil
        XCTAssertNotNil(de.getQrCodePayload())
    }

    
}
