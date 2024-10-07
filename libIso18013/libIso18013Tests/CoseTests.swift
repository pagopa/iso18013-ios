//
//  CoseTests.swift
//  libIso18013
//
//  Created by Antonio Caparello on 07/10/24.
//
import XCTest
import SwiftCBOR

@testable import libIso18013

final class CoseTests: XCTestCase {
  
  func testSignFunction() {
    let data = "this is test data".data(using: .utf8)!
    
    let privateKey = CoseKeyPrivate(crv: .p256)
    
    let coseData = try! Cose.makeCoseSign1(payloadData: data, deviceKey: privateKey, alg: .es256)
    
    let publicKey = privateKey.key
    
    assert(try! coseData.validateCoseSign1(publicKey_x963: publicKey.getx963Representation()))
  }
}
