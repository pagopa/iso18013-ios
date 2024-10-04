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
}

// Class implementing the LibIso18013UtilsProtocol for decoding documents
public class LibIso18013Utils: LibIso18013UtilsProtocol {
    
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

