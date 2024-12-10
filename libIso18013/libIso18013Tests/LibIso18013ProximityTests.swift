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
    func didChangeStatus(_ newStatus: libIso18013.TransferStatus) {
        
    }
    
    func didReceiveRequest(deviceRequest: libIso18013.DeviceRequest, sessionEncryption: libIso18013.SessionEncryption, onResponse: @escaping (Bool, libIso18013.DeviceResponse?) -> Void) {
        
    }
    
    func didFinishedWithError(_ error: any Error) {
        
    }
    
}
