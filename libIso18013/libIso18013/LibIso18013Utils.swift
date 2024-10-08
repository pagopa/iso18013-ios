//
//  LibIso18013Utils.swift
//  libIso18013
//
//  Created by Antonio on 01/10/24.
//

import Foundation

// Protocol definition for LibIso18013UtilsProtocol
public protocol LibIso18013UtilsProtocol {
    // Decodes a document from a base64-encoded string
    func decodeDocument(base64Encoded: String) throws -> Document
    
    // Decodes a document from raw Data
    func decodeDocument(data: Data) throws -> Document
    
    // Decodes a device document from raw Data and private key
    func decodeDeviceDocument(documentData: Data, privateKeyBase64Encoded: String) throws -> DeviceDocument
    
    // Decodes a device document from a base64-encoded string and private key
    func decodeDeviceDocument(documentBase64Encoded: String, privateKeyBase64Encoded: String) throws -> DeviceDocument
    
    // Checks if the given private key corresponds to the document
    func isDevicePrivateKeyOfDocument(document: Document, privateKey: CoseKeyPrivate) -> Bool
    
    // Checks if the given private key (base64 encoded) corresponds to the document
    func isDevicePrivateKeyOfDocument(document: Document, privateKeyBase64Encoded: String) -> Bool
}


public class LibIso18013Utils : LibIso18013UtilsProtocol {
    
    public static let shared = LibIso18013Utils()
    
    // Decodes a device document from raw Data and private key
    // - Parameters:
    //   - documentData: A Data object containing the document data
    //   - privateKeyBase64Encoded: A string containing the base64-encoded private key
    // - Throws: An error if decoding fails
    // - Returns: A DeviceDocument object if decoding succeeds
    public func decodeDeviceDocument(documentData: Data, privateKeyBase64Encoded: String) throws -> DeviceDocument {
        let document = try decodeDocument(data: documentData)
        guard let devicePrivateKey = CoseKeyPrivate(base64: privateKeyBase64Encoded),
              isDevicePrivateKeyOfDocument(document: document, privateKey: devicePrivateKey) else {
            throw ErrorHandler.documentDecodingFailedError
        }
        return DeviceDocument(document: document, devicePrivateKey: devicePrivateKey)
    }
    
    // Decodes a device document from a base64-encoded string and private key
    // - Parameters:
    //   - documentBase64Encoded: A string containing the base64-encoded document data
    //   - privateKeyBase64Encoded: A string containing the base64-encoded private key
    // - Throws: An error if decoding fails
    // - Returns: A DeviceDocument object if decoding succeeds
    public func decodeDeviceDocument(documentBase64Encoded: String, privateKeyBase64Encoded: String) throws -> DeviceDocument {
        let document = try decodeDocument(base64Encoded: documentBase64Encoded)
        guard let devicePrivateKey = CoseKeyPrivate(base64: privateKeyBase64Encoded),
              isDevicePrivateKeyOfDocument(document: document, privateKey: devicePrivateKey) else {
            throw ErrorHandler.documentDecodingFailedError
        }
        return DeviceDocument(document: document, devicePrivateKey: devicePrivateKey)
    }
    
    // Checks if the provided private key corresponds to the device key in the document
    // - Parameters:
    //   - document: The document containing the issuer's signed data
    //   - privateKey: The private key to be checked
    // - Returns: A boolean indicating whether the private key matches the device key in the document
    public func isDevicePrivateKeyOfDocument(document: Document, privateKey: CoseKeyPrivate) -> Bool {
        guard let devicePublicKeyInDocument = document.issuerSigned.issuerAuth?.mobileSecurityObject.deviceKeyInfo.deviceKey else {
            return false
        }
        
        let devicePublicKey = privateKey.key
        
        return devicePublicKeyInDocument.getx963Representation() == devicePublicKey.getx963Representation()
    }
    
    // Checks if the provided base64-encoded private key corresponds to the device key in the document
    // - Parameters:
    //   - document: The document containing the issuer's signed data
    //   - privateKeyBase64Encoded: A base64-encoded string representing the private key
    // - Returns: A boolean indicating whether the private key matches the device key in the document
    public func isDevicePrivateKeyOfDocument(document: Document, privateKeyBase64Encoded: String) -> Bool {
        guard let devicePrivateKey = CoseKeyPrivate(base64: privateKeyBase64Encoded) else {
            return false
        }
        
        return isDevicePrivateKeyOfDocument(document: document, privateKey: devicePrivateKey)
    }

    
    // Decodes a document from a base64-encoded string
    // - Parameter base64Encoded: A string containing the base64-encoded document data
    // - Throws: An error if decoding fails
    // - Returns: A Document object if decoding succeeds
    public func decodeDocument(base64Encoded: String) throws -> Document {
        guard let documentData = Data(base64Encoded: base64Encoded) else {
            throw ErrorHandler.invalidBase64EncodingError
        }
        return try decodeDocument(data: documentData)
    }
    
    
    // Decodes a document from raw Data
    // - Parameter data: A Data object containing the document data
    // - Throws: An error if decoding fails
    // - Returns: A Document object if decoding succeeds
    public func decodeDocument(data: Data) throws -> Document {
        guard let document = Document(data: [UInt8](data)) else {
            throw ErrorHandler.documentDecodingFailedError
        }
        return document
    }
}

