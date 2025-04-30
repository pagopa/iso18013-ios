//
//  DeviceRequestTests.swift
//  IOWalletProximity
//
//  Created by Antonio Caparello on 29/04/25.
//

import XCTest
import Security
internal import SwiftCBOR

@testable import IOWalletProximity

class DeviceRequestTests: XCTestCase {
    func testDeviceRequestToJson() {
        
        guard let deviceRequest = DeviceRequest(data: AnnexdTestData.d411.bytes) else {
            XCTFail("failed to decode deviceRequest")
            return
        }
        
        let json = Proximity().buildDeviceRequestJson(item: deviceRequest)
        
        json.forEach({
            docRequest in
            //isAuthenticated must be false as we are not initializing the sessiontranscript nor passing IACA certificates
            XCTAssert(!docRequest.isAuthenticated)
        })
    }
}
