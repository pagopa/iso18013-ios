//
//  IssuerSignedTests.swift
//  IOWalletProximity
//
//  Created by antoniocaparello on 08/04/26.
//

import XCTest
internal import SwiftCBOR
internal import OrderedCollections
@testable import IOWalletProximity

class IssuerSignedItemTests: XCTestCase {
    
    func testIssuerSignedItemOk() {
        let item1 = IssuerSignedItem(digestID: UInt64(Int32.max) - 1, random: [0x01, 0x02], elementIdentifier: "item1", elementValue: .utf8String("value1"), rawData: nil)
        
        XCTAssertEqual(item1.elementIdentifier, "item1")
        XCTAssertEqual(item1.elementValue, .utf8String("value1"))
    }
    
    func testIssuerSignedItemKo() {
        let item1 = IssuerSignedItem(digestID: UInt64(Int32.max) + 1, random: [0x01, 0x02], elementIdentifier: "item1", elementValue: .utf8String("value1"), rawData: nil)
        
        let cborItem1 = item1.toCBOR(options: CBOROptions())
        
        do {
            //should throw
            let _ = try IssuerSignedItem(cbor: cborItem1)
            
            XCTAssert(false)
        } catch {
            if let e = error as? ErrorHandler {
                XCTAssertEqual(e, .digestIdOutOfRange)
                return
            }
            //should throw exception above
            XCTAssert(false)
        }
    }
    
    func testIssuerSignedKo() {
        
        do {
            //should throw
            let _ = try IssuerSigned(data: Data(base64Encoded: DocumentTestData.document2)!.bytes)
            
            XCTAssert(false)
        } catch {
            if let e = error as? ErrorHandler {
                XCTAssertEqual(e, .digestIdOutOfRange)
                return
            }
            //should throw exception above
            XCTAssert(false)
        }
    }
    
    
    
    
}
