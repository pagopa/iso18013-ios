//
//  CoseTests.swift
//  libIso18013
//
//  Created by Antonio on 09/10/24.
//

import XCTest
internal import SwiftCBOR
@testable import libIso18013

final class CoseTests: XCTestCase {
    
    func testCoseKeyPrivateNormalEncoding() {
        guard let deviceKey = try? LibIso18013Utils.shared.createSecurePrivateKey(curve: .p384, forceSecureEnclave: false) else {
            XCTAssert(false)
            return
        }
        
        let encodedDeviceKey = deviceKey.encode(options: CBOROptions())
        
        guard let decodedDeviceKey = CoseKeyPrivate(data: encodedDeviceKey) else {
            XCTAssert(false)
            return
        }
        
        XCTAssert(decodedDeviceKey.secureEnclaveKeyID == nil)
        
        XCTAssert(decodedDeviceKey.getx963Representation() == deviceKey.getx963Representation())
        
        let dataToSignString = "this is test data"
        
        let dataToSign = dataToSignString.data(using: .utf8)!
        
        let coseObject = try! Cose.makeCoseSign1(payloadData: dataToSign, deviceKey: deviceKey, alg: .es384)
        
        let isValid = try? coseObject.validateCoseSign1(publicKey_x963: decodedDeviceKey.key.getx963Representation())
        
        let coseObject1 = try! Cose.makeCoseSign1(payloadData: dataToSign, deviceKey: decodedDeviceKey, alg: .es384)
        
        let isValid1 = try? coseObject1.validateCoseSign1(publicKey_x963: deviceKey.key.getx963Representation())
        
        XCTAssert(isValid == true)
        XCTAssert(isValid1 == true)
        
    }
    
    func testCoseKeyPrivateSecureEnclaveEncoding() {
        guard let deviceKey = try? LibIso18013Utils.shared.createSecurePrivateKey() else {
            XCTAssert(false)
            return
        }
        
        let encodedDeviceKey = deviceKey.encode(options: CBOROptions())
        
        guard let decodedDeviceKey = CoseKeyPrivate(data: encodedDeviceKey) else {
            XCTAssert(false)
            return
        }
        
        XCTAssert(decodedDeviceKey.secureEnclaveKeyID != nil)
        
        XCTAssert(decodedDeviceKey.secureEnclaveKeyID == deviceKey.secureEnclaveKeyID)
        
        let dataToSignString = "this is test data"
        
        let dataToSign = dataToSignString.data(using: .utf8)!
        
        let coseObject = try! Cose.makeCoseSign1(payloadData: dataToSign, deviceKey: deviceKey, alg: .es256)
        
        let isValid = try? coseObject.validateCoseSign1(publicKey_x963: decodedDeviceKey.key.getx963Representation())
        
        let coseObject1 = try! Cose.makeCoseSign1(payloadData: dataToSign, deviceKey: decodedDeviceKey, alg: .es256)
        
        let isValid1 = try? coseObject1.validateCoseSign1(publicKey_x963: deviceKey.key.getx963Representation())
        
        XCTAssert(isValid == true)
        XCTAssert(isValid1 == true)
        
    }
    
    func testSignData() {
        let dataToSignString = "this is test data"
        
        let dataToSign = dataToSignString.data(using: .utf8)!
        
        let privateKey = CoseKeyPrivate(crv: .p256)
        let publicKey = privateKey.key
        
        let coseObject = try! Cose.makeCoseSign1(payloadData: dataToSign, deviceKey: privateKey, alg: .es256)
        
        let coseEncoded = coseObject.encode(options: CBOROptions())
        
        guard let coseDecodedCbor = try? CBOR.decode(coseEncoded) else {
            XCTAssert(false) //cbor decoding failed
            return
        }
        
        guard let coseDecoded = Cose(type: .sign1, cbor: coseDecodedCbor) else {
            XCTAssert(false) //cose init failed
            return
        }
        
        guard let isValidSignature = try? coseDecoded.validateCoseSign1(publicKey_x963: publicKey.getx963Representation()) else {
            XCTAssert(false) //validateCoseSign1 failed with exception
            return
        }
        
        XCTAssert(isValidSignature)
    }
    
    func testSignedData() {
        let payloadToVerify = "this is test data"
        
        let coseObjectBase64 = "hEOhASagUXRoaXMgaXMgdGVzdCBkYXRhWECWHFXxcZPkyupozacO5KTeBDcbXFYX6HaFynTZ85qXdtGGd9bhtgBq1vcjYdK0QHP+DmG15108cm497i83ScSf"
        
        let validPublicKey1Base64 = "pCABAQIhWCBGNvJAmcQpm4EhDvWYsxWzT7Lm7N0R7X6kAswyi5yqVCJYIIZVRZ4ujdrKimOlytyhpqlOJu2PlOtOhJSSkbzUNJx+"
        let notValidPublicKey1Base64 = "pCABAQIhWCA2hqj0DAvEr7gRsTRLXu7Y8nBlpCIgoDNXtnMmZg8wVSJYIHse1ypD88D0cmS/R6R0f83bE/9GetTg9aPDozHTdvfB"
        
        guard let validPublicKeyData = Data(base64Encoded: validPublicKey1Base64) else {
            XCTAssert(false) //base64 decoding failed
            return
        }
        
        guard let notValidPublicKeyData = Data(base64Encoded: notValidPublicKey1Base64) else {
            XCTAssert(false) //base64 decoding failed
            return
        }
        
        guard let coseDecodedData = Data(base64Encoded: coseObjectBase64) else {
            XCTAssert(false) //base64 decoding failed
            return
        }
        
        guard let coseDecodedCbor = try? CBOR.decode(coseDecodedData.bytes) else {
            XCTAssert(false) //cbor decoding failed
            return
        }
        
        guard let coseDecoded = Cose(type: .sign1, cbor: coseDecodedCbor) else {
            XCTAssert(false) //cose init failed
            return
        }
        
        guard let validPublicKey = CoseKey(data: validPublicKeyData.bytes) else {
            XCTAssert(false) //CoseKey CBOR decoding failed
            return
        }
        
        guard let notValidPublicKey = CoseKey(data: notValidPublicKeyData.bytes) else {
            XCTAssert(false) //CoseKey CBOR decoding failed
            return
        }
       
        guard let isValidSignature = try? coseDecoded.validateCoseSign1(publicKey_x963: validPublicKey.getx963Representation()) else {
            XCTAssert(false) //validateCoseSign1 failed with exception
            return
        }
        
        guard let isNotValidSignature = try? coseDecoded.validateCoseSign1(publicKey_x963: notValidPublicKey.getx963Representation()) else {
            XCTAssert(false) //validateCoseSign1 failed with exception
            return
        }
        
        XCTAssert(isValidSignature)
        XCTAssert(!isNotValidSignature)
        
        guard let rawPayload = coseDecoded.payload.asBytes() else {
            XCTAssert(false) //cose payload not decodable
            return
        }
        
        guard let stringPayload = String(data: Data(rawPayload), encoding: .utf8) else {
            XCTAssert(false) //cose payload not utf8 string
            return
        }
        
        XCTAssert(stringPayload == payloadToVerify)
    }
    
    
    
}
