//
//  Document.swift
//  libIso18013
//
//  Created by Antonio on 02/10/24.
//


import Foundation
import SwiftCBOR
import OrderedCollections

// Struct representing a Document, including its type, issuer-signed data, and optional errors
public struct Document {
    
    // The type of document
    public let docType: String
    
    // The issuer-signed data associated with the document
    public let issuerSigned: IssuerSigned
    
    // Optional errors associated with the document
    public let errors: Errors?
    
    // Enum defining keys for CBOR encoding/decoding
    enum Keys: String {
        case docType
        case issuerSigned
        case deviceSigned
        case errors
    }
    
    // Initializer for Document
    // - Parameters:
    //   - docType: The type of the document
    //   - issuerSigned: Issuer-signed data for the document
    //   - errors: Optional Errors associated with the document
    public init(docType: String, issuerSigned: IssuerSigned, errors: Errors? = nil) {
        self.docType = docType
        self.issuerSigned = issuerSigned
        self.errors = errors
    }
}

// Extension to make Document conform to CBORDecodable
extension Document: CBORDecodable {
    
    // Initializes a Document from a CBOR object
    // - Parameter cbor: The CBOR object representing the document
    public init?(cbor: CBOR) {
        
        // Ensure the CBOR object is a map
        guard case .map(let cborMap) = cbor else {
            return nil
        }
        
        // Extract the document type from the CBOR map
        guard case .utf8String(let docType) = cborMap[Keys.docType] else {
            return nil
        }
        self.docType = docType
        
        // Extract the issuer-signed data from the CBOR map
        guard let cborIssuerSigned = cborMap[Keys.issuerSigned],
              let issuerSigned = IssuerSigned(cbor: cborIssuerSigned) else {
            return nil
        }
        self.issuerSigned = issuerSigned
        
        // Extract the optional errors from the CBOR map
        if let cborErrors = cborMap[Keys.errors],
           let errors = Errors(cbor: cborErrors) {
            self.errors = errors
        } else {
            self.errors = nil
        }
    }
}

// Extension to make Document conform to CBOREncodable
extension Document: CBOREncodable {
    
    // Encodes the Document into a CBOR object
    // - Parameter options: Encoding options for CBOR
    // - Returns: A CBOR object representing the encoded Document
    public func toCBOR(options: CBOROptions) -> CBOR {
        var cbor = OrderedDictionary<CBOR, CBOR>()
        
        // Add the document type to the CBOR map
        cbor[.utf8String(Keys.docType.rawValue)] = .utf8String(docType)
        
        // Add the issuer-signed data to the CBOR map
        cbor[.utf8String(Keys.issuerSigned.rawValue)] = issuerSigned.toCBOR(options: options)
        
        // Add the errors to the CBOR map if they exist
        if let errors {
            cbor[.utf8String(Keys.errors.rawValue)] = errors.toCBOR(options: options)
        }
        
        // Return the encoded CBOR map
        return .map(cbor)
    }
}
