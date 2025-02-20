//
//  LibIso18013ProximityTests.swift
//  libIso18013
//
//  Created by Martina D'urso on 18/10/24.
//

import XCTest
@testable import IOWalletProximity

class LibIso18013ProximityTests: XCTestCase {
    func testSetListener() {
        let listener = MockQrEngagementListener()
        let proximityLib = LibIso18013Proximity.shared
        
        proximityLib.setListener(listener)
        XCTAssertNotNil(proximityLib.listener)
    }
    
    func testGetQrCodePayload() throws {
        let proximityLib = LibIso18013Proximity.shared
        
        let listener = MockQrEngagementListener()
        
        proximityLib.setListener(listener)
        
        XCTAssertNoThrow(try {
            let payload = try proximityLib.getQrCodePayload()
            XCTAssertFalse(payload.isEmpty, "QR code payload should not be empty")
        }())
    }
}

class MockQrEngagementListener: QrEngagementListener {
    func didChangeStatus(_ newStatus: IOWalletProximity.TransferStatus) {
        
    }
    
    func didReceiveRequest(deviceRequest: IOWalletProximity.DeviceRequest, sessionEncryption: IOWalletProximity.SessionEncryption, onResponse: @escaping (Bool, IOWalletProximity.DeviceResponse?) -> Void) {
        
    }
    
    func didFinishedWithError(_ error: any Error) {
        
    }
    
}
