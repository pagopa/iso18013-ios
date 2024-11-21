//
//  libIso18013Tests.swift
//  libIso18013Tests
//
//  Created by Antonio on 01/10/24.
//

import XCTest
@testable import libIso18013

final class libIso18013Tests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testCoseCbor() {
        
    }
    
    func testCbor2() {
        let json = CborCose.shared.decodeCBOR(data: Data(base64Encoded: "2BhZAlSmZ2RvY1R5cGV3ZXUuZXVyb3BhLmVjLmV1ZGkucGlkLjFndmVyc2lvbmMxLjBsdmFsaWRpdHlJbmZvo2ZzaWduZWTAdDIwMjQtMTAtMTFUMDc6MDE6MTFaaXZhbGlkRnJvbcB0MjAyNC0xMC0xMVQwNzowMToxMVpqdmFsaWRVbnRpbMB0MjAyNS0wMS0wOVQwMDowMDowMFpsdmFsdWVEaWdlc3RzoXdldS5ldXJvcGEuZWMuZXVkaS5waWQuMagAWCA/9LdfuZTYjZVBtgYWGHGTKy2ItELLK24kyvBa+fZtBgFYIKcinWaerp+huMS4RcNth/71oS65G8soNmziNdsQbPZ7AlggHDbzU61j9bzgsVSGKCKmP55zFBx/fl0dC5i2s9wVyUsDWCAMSL5k3wsaZCvgJWS62Y5KW1Jw5StDYbIRWmaqLNRhsARYIG2cfJbnrIb6JFlEcxQsITtmqmNUKiAkXe8BKrlBzBjaBVgg/Z+V4zYB4jk4B/mlvNyX9IiexeMzb7xutpee7Ckox/4GWCBH0KG6NVpu3IU0p4eE4pMgQ/HVOkLGE0ls4rNR0WNRmAdYILb8I/BRkRFc0TA2CZQrXBADrWvLr9HLEgvVBoASJqavbWRldmljZUtleUluZm+haWRldmljZUtleaQBAiABIVggddMuWPOuHcgcm/zu1WFyAGCIH+4zffP3ekD4RSrT0uQiWCAUd6T53FdBgJ0iUfGZdF6HWXw0yXDJ5xdktg5JW6jI029kaWdlc3RBbGdvcml0aG1nU0hBLTI1Ng==")!)
        
        print(json)
    }
    
    func testCborToJson() {
        let json = CborCose.shared.decodeCBOR(data: Data(base64Encoded: DocumentTestData.document1)!)
        
        print(json!)
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testDecodeDE1() throws {
        let de = try XCTUnwrap(DeviceEngagement(data: AnnexdTestData.d31.bytes))
        XCTAssertEqual(de.version, "1.0")
        XCTAssertEqual(de.deviceRetrievalMethods?.first, .ble(isBleServer: false, uuid: "45EFEF742B2C4837A9A3B0E1D05A6917"))
    }
    
    func testEncodeDE() throws {
        let de1 = try XCTUnwrap(DeviceEngagement(data: OtherTestData.deOnline.bytes))
        let de1data = de1.encode(options: .init())
        XCTAssertNotNil(de1data)
    }
    
    func testGenerateBLEengageQRCodePayload() throws {
        var de = DeviceEngagement(isBleServer: true)
        XCTAssertNotNil(de.getQrCodePayload())
    }

}
