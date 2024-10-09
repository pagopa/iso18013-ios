//
//  CoseTests.swift
//  libIso18013
//
//  Created by Antonio on 09/10/24.
//

import XCTest
import SwiftCBOR
@testable import libIso18013

final class CoseTests: XCTestCase {
    
    func testSignData() {
        let dataToSignString = "this is test data"
        
        let dataToSign = dataToSignString.data(using: .utf8)!
        
        let privateKey = CoseKeyPrivate(crv: .p256)
        let publicKey = privateKey.key
        
        let coseObject = try! Cose.makeCoseSign1(payloadData: dataToSign, deviceKey: privateKey, alg: .es256)
        
        let coseEncoded = coseObject.encode(options: CBOROptions())
        
        guard let coseDecodedCbor = try? CBOR.decode(coseEncoded) else {
            assert(false) //cbor decoding failed
        }
        
        guard let coseDecoded = Cose(type: .sign1, cbor: coseDecodedCbor) else {
            assert(false) //cose init failed
        }
        
        guard let isValidSignature = try? coseDecoded.validateCoseSign1(publicKey_x963: publicKey.getx963Representation()) else {
            assert(false) //validateCoseSign1 failed with exception
        }
        
        assert(isValidSignature)
    }
    
    func testSignedData() {
        let payloadToVerify = "this is test data"
        
        let coseObjectBase64 = "hEOhASagUXRoaXMgaXMgdGVzdCBkYXRhWECWHFXxcZPkyupozacO5KTeBDcbXFYX6HaFynTZ85qXdtGGd9bhtgBq1vcjYdK0QHP+DmG15108cm497i83ScSf"
        
        let validPublicKey1Base64 = "pCABAQIhWCBGNvJAmcQpm4EhDvWYsxWzT7Lm7N0R7X6kAswyi5yqVCJYIIZVRZ4ujdrKimOlytyhpqlOJu2PlOtOhJSSkbzUNJx+"
        let notValidPublicKey1Base64 = "pCABAQIhWCA2hqj0DAvEr7gRsTRLXu7Y8nBlpCIgoDNXtnMmZg8wVSJYIHse1ypD88D0cmS/R6R0f83bE/9GetTg9aPDozHTdvfB"
        
        guard let validPublicKeyData = Data(base64Encoded: validPublicKey1Base64) else {
            assert(false) //base64 decoding failed
        }
        
        guard let notValidPublicKeyData = Data(base64Encoded: notValidPublicKey1Base64) else {
            assert(false) //base64 decoding failed
        }
        
        guard let coseDecodedData = Data(base64Encoded: coseObjectBase64) else {
            assert(false) //base64 decoding failed
        }
        
        guard let coseDecodedCbor = try? CBOR.decode(coseDecodedData.bytes) else {
            assert(false) //cbor decoding failed
        }
        
        guard let coseDecoded = Cose(type: .sign1, cbor: coseDecodedCbor) else {
            assert(false) //cose init failed
        }
        
        guard let validPublicKey = CoseKey(data: validPublicKeyData.bytes) else {
            assert(false) //CoseKey CBOR decoding failed
        }
        
        guard let notValidPublicKey = CoseKey(data: notValidPublicKeyData.bytes) else {
            assert(false) //CoseKey CBOR decoding failed
        }
       
        guard let isValidSignature = try? coseDecoded.validateCoseSign1(publicKey_x963: validPublicKey.getx963Representation()) else {
            assert(false) //validateCoseSign1 failed with exception
        }
        
        guard let isNotValidSignature = try? coseDecoded.validateCoseSign1(publicKey_x963: notValidPublicKey.getx963Representation()) else {
            assert(false) //validateCoseSign1 failed with exception
        }
        
        assert(isValidSignature)
        assert(!isNotValidSignature)
        
        guard let rawPayload = coseDecoded.payload.asBytes() else {
            assert(false) //cose payload not decodable
        }
        
        guard let stringPayload = String(data: Data(rawPayload), encoding: .utf8) else {
            assert(false) //cose payload not utf8 string
        }
        
        assert(stringPayload == payloadToVerify)
    }
    
    
    
}
