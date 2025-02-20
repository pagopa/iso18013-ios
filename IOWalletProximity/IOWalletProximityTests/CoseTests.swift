//
//  CoseTests.swift
//  libIso18013
//
//  Created by Antonio on 09/10/24.
//

import XCTest
internal import SwiftCBOR
@testable import IOWalletProximity
import CryptoKit

final class CoseTests: XCTestCase {
    
    func testCoseKeyExchange() {
        
        let salt = "TEST_SALT".data(using: .utf8)!.bytes
        let info = "TEST_INFO".data(using: .utf8)!
        
        
        let alice = P256.KeyAgreement.PrivateKey()
        let bob = P256.KeyAgreement.PrivateKey()
        let clara = P256.KeyAgreement.PrivateKey()
        
        let alicePrivatex963 = alice.x963Representation
        let alicePublicx963 = alice.publicKey.x963Representation
        
        let bobPrivatex963 = bob.x963Representation
        let bobPublicx963 = bob.publicKey.x963Representation
        
        let claraPrivatex963 = clara.x963Representation
        let claraPublicx963 = clara.publicKey.x963Representation
        
        let alicePublicCoseKey = CoseKey(crv: .p256, x963Representation: alicePublicx963)
        let alicePrivateCoseKey = CoseKeyPrivate(privateKeyx963Data: alicePrivatex963, crv: .p256)
        let alicePrivateSecKey = secKeyFromX963(alicePrivatex963, true)!
        let alicePrivateSecCoseKey = CoseKeyPrivate(crv: .p256, secKey: alicePrivateSecKey)!
        
        
        let bobPublicCoseKey = CoseKey(crv: .p256, x963Representation: bobPublicx963)
        let bobPrivateCoseKey = CoseKeyPrivate(privateKeyx963Data: bobPrivatex963, crv: .p256)
        let bobPrivateSecKey = secKeyFromX963(bobPrivatex963, true)!
        let bobPrivateSecCoseKey = CoseKeyPrivate(crv: .p256, secKey: bobPrivateSecKey)!
        
        let claraPublicCoseKey = CoseKey(crv: .p256, x963Representation: claraPublicx963)
        let claraPrivateCoseKey = CoseKeyPrivate(privateKeyx963Data: claraPrivatex963, crv: .p256)
        let claraPrivateSecKey = secKeyFromX963(claraPrivatex963, true)!
        let claraPrivateSecCoseKey = CoseKeyPrivate(crv: .p256, secKey: claraPrivateSecKey)!
        
        
        let aliceAndBob = CoseKeyExchange(publicKey: bobPublicCoseKey, privateKey: alicePrivateCoseKey)
        let aliceAndBobSec = CoseKeyExchange(publicKey: bobPublicCoseKey, privateKey: alicePrivateSecCoseKey)
        
        let bobAndAlice = CoseKeyExchange(publicKey: alicePublicCoseKey, privateKey: bobPrivateCoseKey)
        let bobAndAliceSec = CoseKeyExchange(publicKey: alicePublicCoseKey, privateKey: bobPrivateSecCoseKey)
        
        
        let aliceAndClara = CoseKeyExchange(publicKey: claraPublicCoseKey, privateKey: alicePrivateCoseKey)
        let aliceAndClaraSec = CoseKeyExchange(publicKey: claraPublicCoseKey, privateKey: alicePrivateSecCoseKey)
        
        let aliceAndBobShared = aliceAndBob.makeEckaDHAgreement(inSecureEnclave: false)!
        let aliceAndBobSharedSec = aliceAndBobSec.makeEckaDHAgreementSecurity()!
        
        let bobAndAliceShared = bobAndAlice.makeEckaDHAgreement(inSecureEnclave: false)!
        let bobAndAliceSharedSec = bobAndAliceSec.makeEckaDHAgreementSecurity()!
        
        
        let aliceAndClaraShared = aliceAndClara.makeEckaDHAgreement(inSecureEnclave: false)!
        let aliceAndClaraSharedSec = aliceAndClaraSec.makeEckaDHAgreementSecurity()!
        
        
        let aliceAndBobKey = try! SessionEncryption.HMACKeyDerivationFunction(sharedSecret: aliceAndBobShared, salt: salt, info: info)
        let aliceAndBobKeySec = SessionEncryption.HMACKeyDerivationFunction(sharedSecret: aliceAndBobSharedSec, salt: salt, info: info)
        
        let bobAndAliceKey = try! SessionEncryption.HMACKeyDerivationFunction(sharedSecret: bobAndAliceShared, salt: salt, info: info)
        let bobAndAliceKeySec = SessionEncryption.HMACKeyDerivationFunction(sharedSecret: bobAndAliceSharedSec, salt: salt, info: info)
        
        let aliceAndClaraKey = try! SessionEncryption.HMACKeyDerivationFunction(sharedSecret: aliceAndClaraShared, salt: salt, info: info)
        let aliceAndClaraKeySec = SessionEncryption.HMACKeyDerivationFunction(sharedSecret: aliceAndClaraSharedSec, salt: salt, info: info)
        
        
        //Asserts that keys generated with crypto and security are equal
        XCTAssert(aliceAndBobKey == aliceAndBobKeySec)
        XCTAssert(bobAndAliceKey == bobAndAliceKeySec)
        XCTAssert(aliceAndClaraKey == aliceAndClaraKeySec)
        
        //Asserts that keys generated from bobAndAlice are equal to keys generated from aliceAndBob
        XCTAssert(aliceAndBobKey == bobAndAliceKey)
        XCTAssert(aliceAndBobKeySec == bobAndAliceKeySec)
        
        
        //Asserts that keys generated from aliceAndClara are not equal to keys generated from aliceAndBob
        XCTAssert(aliceAndBobKeySec != aliceAndClaraKey)
        XCTAssert(aliceAndBobKeySec != aliceAndClaraKeySec)
        
    }
    
    
    
    func secKeyFromX963(_ x963: Data, _ isPrivate: Bool) -> SecKey? {
        var error: Unmanaged<CFError>?
        
        let secKey = SecKeyCreateWithData(
            Data(x963) as CFData,
            [
                kSecAttrKeyClass: isPrivate ? kSecAttrKeyClassPrivate : kSecAttrKeyClassPublic,
                kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
            ] as CFDictionary, &error)
        
        print(error)
        
        return secKey
    }
    
    
    
    
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
