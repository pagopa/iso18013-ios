//
//  LibIso18013Utils.swift
//  libIso18013
//
//  Created by Antonio on 01/10/24.
//

import Foundation

// Protocol defining methods for decoding documents from base64 or Data
public protocol LibIso18013UtilsProtocol {
  
  // Decodes a document from a base64-encoded string
  func decodeDocument(base64Encoded: String) -> Document?

  // Decodes a document from raw Data
  func decodeDocument(data: Data) -> Document?
  
  func decodeDeviceDocument(documentData: Data, privateKeyBase64Encoded: String) -> DeviceDocument?
  func decodeDeviceDocument(documentBase64Encoded: String, privateKeyBase64Encoded: String) -> DeviceDocument?
  
  func isDevicePrivateKeyOfDocument(document: Document, privateKey: CoseKeyPrivate) -> Bool
  func isDevicePrivateKeyOfDocument(document: Document, privateKeyBase64Encoded: String) -> Bool
}


public class LibIso18013Utils : LibIso18013UtilsProtocol {

  public static let shared = LibIso18013Utils()
    
  public func decodeDeviceDocument(documentData: Data, privateKeyBase64Encoded: String) -> DeviceDocument? {
    guard let document = decodeDocument(data: documentData),
          let devicePrivateKey = CoseKeyPrivate(base64: privateKeyBase64Encoded),
          isDevicePrivateKeyOfDocument(document: document, privateKey: devicePrivateKey) else {
      return nil
    }
    
    return DeviceDocument(document: document, devicePrivateKey: devicePrivateKey)
  }
  
  public func decodeDeviceDocument(documentBase64Encoded: String, privateKeyBase64Encoded: String) -> DeviceDocument? {
    guard let document = decodeDocument(base64Encoded: documentBase64Encoded),
          let devicePrivateKey = CoseKeyPrivate(base64: privateKeyBase64Encoded),
          isDevicePrivateKeyOfDocument(document: document, privateKey: devicePrivateKey) else {
      return nil
    }
    
    return DeviceDocument(document: document, devicePrivateKey: devicePrivateKey)
  }
  
  public func isDevicePrivateKeyOfDocument(document: Document, privateKey: CoseKeyPrivate) -> Bool {
    guard let devicePublicKeyInDocument = document.issuerSigned.issuerAuth?.mobileSecurityObject.deviceKeyInfo.deviceKey else {
      return false
    }
    
    let devicePublicKey = privateKey.key;
    
    return devicePublicKeyInDocument.getx963Representation() == devicePublicKey.getx963Representation()
  }
  
  public func isDevicePrivateKeyOfDocument(document: Document, privateKeyBase64Encoded: String) -> Bool {
    guard let devicePrivateKey = CoseKeyPrivate(base64: privateKeyBase64Encoded) else {
      return false
    }
    
    return isDevicePrivateKeyOfDocument(document: document, privateKey: devicePrivateKey)
   
  }
  // Decodes a document from a base64-encoded string
  // - Parameter base64Encoded: A string containing the base64-encoded document data
  // - Returns: A Document object if decoding succeeds, or nil if it fails
  public func decodeDocument(base64Encoded: String) -> Document? {
    guard let documentData = Data(base64Encoded: base64Encoded) else {
      return nil
    }
    return decodeDocument(data: documentData)
  }

  // Decodes a document from raw Data
  // - Parameter data: A Data object containing the document data
  // - Returns: A Document object if decoding succeeds
  public func decodeDocument(data: Data) -> Document? {
        return Document(data: [UInt8](data))
    }
}

