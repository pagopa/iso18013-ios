//
//  LibIso18013ProximityTests.swift
//  libIso18013
//
//  Created by Martina D'urso on 18/10/24.
//

import XCTest
@testable import libIso18013

class LibIso18013ProximityTests: XCTestCase {
    func testSetListener() {
        let listener = MockQrEngagementListener()
        let proximityLib = LibIso18013Proximity.shared
        
        proximityLib.setListener(listener)
        XCTAssertNotNil(proximityLib.listener)
    }
    
    func testGetQrCodePayload() throws {
        let proximityLib = LibIso18013Proximity.shared
        
        XCTAssertNoThrow(try {
            let payload = try proximityLib.getQrCodePayload()
            XCTAssertFalse(payload.isEmpty, "QR code payload should not be empty")
        }())
    }
}

class MockQrEngagementListener: QrEngagementListener {
    var onConnectingCalled = false
    
    func onConnecting() {
        onConnectingCalled = true
    }
}
