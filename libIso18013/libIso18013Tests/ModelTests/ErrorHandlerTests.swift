//
//  ErrorHandlerTests.swift
//  libIso18013
//
//  Created by Martina D'urso on 18/10/24.
//


import XCTest
import SwiftCBOR
@testable import libIso18013

class ErrorHandlerTests: XCTestCase {
    
    func testLocalizedDescription() {
        XCTAssertEqual(ErrorHandler.invalidBase64EncodingError.localizedDescription, "Invalid base64 encoding")
        XCTAssertEqual(ErrorHandler.documentDecodingFailedError.localizedDescription, "Document decoding failed")
        XCTAssertEqual(ErrorHandler.invalidDeviceKeyError.localizedDescription, "Invalid device key")
        XCTAssertEqual(ErrorHandler.secureEnclaveNotSupported.localizedDescription, "Secure Enclave not supported on this device")
        XCTAssertEqual(ErrorHandler.documentWithIdentifierNotFound.localizedDescription, "No stored document found with this identifier")
        XCTAssertEqual(ErrorHandler.documentMustBeUnsigned.localizedDescription, "Document must be unsigned")
        XCTAssertEqual(ErrorHandler.documents_not_provided.localizedDescription, "DOCUMENTS_NOT_PROVIDED")
        XCTAssertEqual(ErrorHandler.invalidInputDocument.localizedDescription, "INVALID_INPUT_DOCUMENT")
        XCTAssertEqual(ErrorHandler.invalidUrl.localizedDescription, "INVALID_URL")
        XCTAssertEqual(ErrorHandler.device_private_key_not_provided.localizedDescription, "DEVICE_PRIVATE_KEY_NOT_PROVIDED")
        XCTAssertEqual(ErrorHandler.noDocumentToReturn.localizedDescription, "NO_DOCUMENT_TO_RETURN")
        XCTAssertEqual(ErrorHandler.requestDecodeError.localizedDescription, "REQUEST_DECODE_ERROR")
        XCTAssertEqual(ErrorHandler.userRejected.localizedDescription, "USER_REJECTED")
        XCTAssertEqual(ErrorHandler.bleNotAuthorized.localizedDescription, "BLE_NOT_AUTHORIZED")
        XCTAssertEqual(ErrorHandler.bleNotSupported.localizedDescription, "BLE_NOT_SUPPORTED")
        XCTAssertEqual(ErrorHandler.deviceEngagementMissing.localizedDescription, "DEVICE_ENGAGEMENT_MISSING")
        XCTAssertEqual(ErrorHandler.readerKeyMissing.localizedDescription, "READER_KEY_MISSING")
        XCTAssertEqual(ErrorHandler.sessionEncryptionNotInitialized.localizedDescription, "SESSION_ENCYPTION_NOT_INITIALIZED")
        XCTAssertEqual(ErrorHandler.qrCodePayloadNotFound.localizedDescription, "QRCODE_PAYLOAD_NOT_FOUND")
        XCTAssertEqual(ErrorHandler.unexpected_error.localizedDescription, "GENERIC_ERROR")
    }
    
    func testSecureEnclaveNotSupportedAlgorithmDescription() {
        let algorithm = ECCurveName.p256
        let error = ErrorHandler.secureEnclaveNotSupportedAlgorithm(algorithm: algorithm)
        XCTAssertEqual(error.localizedDescription, "\(algorithm) not supported with Secure Enclave")
    }
}
