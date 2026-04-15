//
//  DigestIDsTests.swift
//  IOWalletProximity
//
//  Created by antoniocaparello on 15/04/26.
//

import XCTest
internal import SwiftCBOR
internal import OrderedCollections
@testable import IOWalletProximity

class DigestIDsTests: XCTestCase {
    
    func testDigestIDsOk() {
        do {
            let digests = try DigestIDs(digestIDs: [
                0: [],
                1: [],
                2: []
            ])
            
            XCTAssert(digests.digestIDs.keys.count(where: { $0 == 0 }) == 1)
            XCTAssert(digests.digestIDs.keys.count(where: { $0 == 1 }) == 1)
            XCTAssert(digests.digestIDs.keys.count(where: { $0 == 2 }) == 1)
        
        } catch {
            //should not throw exception
            XCTAssert(false)
        }
    }
    
    func testDigestIDsKo() {
        do {
            let _ = try DigestIDs(digestIDs: [
                UInt64(Int32.max): [],
                UInt64(Int32.max) + 1: [],
                UInt64(Int32.max) + 2: []
            ])
            //should throw exception
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
