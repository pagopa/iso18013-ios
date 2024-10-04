//
//  DrivingPrivilegesTests.swift
//  libIso18013
//
//  Created by Martina D'urso on 03/10/24.
//

import XCTest
import SwiftCBOR
@testable import libIso18013

final class DrivingPrivilegesTests: XCTestCase {
 
    func testDecodeAndEncodeDrivingPrivileges() throws {
        // Test decoding: verifying the decoded data matches the expected values
        // Unwrapping the decoded DrivingPrivileges object from the test data
        let dps = try XCTUnwrap(DrivingPrivileges(data: AnnexdTestData.d21.bytes))
        
        // Assert the first entry's values are as expected
        XCTAssertEqual(dps[0].vehicleCategoryCode, "A", "Vehicle category code should be 'A'")
        XCTAssertEqual(dps[0].issueDate, "2018-08-09", "Issue date should be '2018-08-09'")
        XCTAssertEqual(dps[0].expiryDate, "2024-10-20", "Expiry date should be '2024-10-20'")
        
        // Assert the second entry's values are as expected
        XCTAssertEqual(dps[1].vehicleCategoryCode, "B", "Vehicle category code should be 'B'")
        XCTAssertEqual(dps[1].issueDate, "2017-02-23", "Issue date should be '2017-02-23'")
        XCTAssertEqual(dps[1].expiryDate, "2024-10-20", "Expiry date should be '2024-10-20'")
        
        // Test encoding: converting the DrivingPrivileges object to CBOR format
        let cborDps = dps.toCBOR(options: CBOROptions())
        
        // Unwrap the object after decoding it back from CBOR format
        let dps2 = try XCTUnwrap(DrivingPrivileges(cbor: cborDps))
        
        // Assert that the re-decoded object matches the original values
        XCTAssertEqual(dps2[0].vehicleCategoryCode, "A", "Vehicle category code should still be 'A' after encoding and decoding")
        XCTAssertEqual(dps2[0].issueDate, "2018-08-09", "Issue date should still be '2018-08-09'")
        XCTAssertEqual(dps2[0].expiryDate, "2024-10-20", "Expiry date should still be '2024-10-20'")
        
        XCTAssertEqual(dps2[1].vehicleCategoryCode, "B", "Vehicle category code should still be 'B' after encoding and decoding")
        XCTAssertEqual(dps2[1].issueDate, "2017-02-23", "Issue date should still be '2017-02-23'")
        XCTAssertEqual(dps2[1].expiryDate, "2024-10-20", "Expiry date should still be '2024-10-20'")
    }
    
}
