//
//  IssuerSigned.swift
//  libIso18013
//
//  Created by Antonio on 02/10/24.
//


import Foundation
import SwiftCBOR
import OrderedCollections

// Struct representing IssuerSigned, containing optional IssuerNameSpaces
public struct IssuerSigned {
    
    // Optional IssuerNameSpaces associated with the issuer
    public let issuerNameSpaces: IssuerNameSpaces?
    
    // Enum defining keys for CBOR encoding/decoding
    enum Keys: String {
        case nameSpaces
        case issuerAuth
    }
    
    // Initializer for IssuerSigned
    // - Parameter issuerNameSpaces: Optional IssuerNameSpaces associated with the issuer
    public init(issuerNameSpaces: IssuerNameSpaces?) {
        self.issuerNameSpaces = issuerNameSpaces
    }
}

// Extension to make IssuerSigned conform to CBORDecodable
extension IssuerSigned: CBORDecodable {
    
    // Initializes IssuerSigned from a CBOR object
    // - Parameter cbor: The CBOR object representing the issuer-signed data
    public init?(cbor: CBOR) {
        // Ensure the CBOR object is a map
        guard case let .map(cborMap) = cbor else {
            return nil
        }
        
        // Attempt to extract IssuerNameSpaces from the CBOR map
        if let issuerNameSpaceCbor = cborMap[Keys.nameSpaces] {
            issuerNameSpaces = IssuerNameSpaces(cbor: issuerNameSpaceCbor)
        } else {
            issuerNameSpaces = nil
        }
    }
}

// Extension to make IssuerSigned conform to CBOREncodable
extension IssuerSigned: CBOREncodable {
    
    // Encodes IssuerSigned into a CBOR object
    // - Parameter options: Encoding options for CBOR
    // - Returns: A CBOR object representing the encoded IssuerSigned data
    public func toCBOR(options: CBOROptions) -> CBOR {
        var cbor = OrderedDictionary<CBOR, CBOR>()
        
        // Encode IssuerNameSpaces if they exist
        if let issuerNameSpaces = issuerNameSpaces {
            cbor[.utf8String(Keys.nameSpaces.rawValue)] = issuerNameSpaces.toCBOR(options: options)
        }
        
        // Return the encoded CBOR map
        return .map(cbor)
    }
}
