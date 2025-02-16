//
//  CoseKey.swift
//  libIso18013
//
//  Created by Antonio on 03/10/24.
//

import SwiftCBOR

// Defined in RFC 8152
struct CoseKey: Equatable {
    // Elliptic curve name
    public let crv: ECCurveName
    // Elliptic curve type
    var kty: ECCurveType
    // X coordinate of the public key
    let x: [UInt8]
    // Y coordinate of the public key
    let y: [UInt8]
}

extension CoseKey: CBOREncodable {
    // Converts the CoseKey to CBOR format
    public func toCBOR(options: CBOROptions) -> CBOR {
        let cbor: CBOR = [
            -1: .unsignedInt(crv.rawValue), // Curve name identifier
             1: .unsignedInt(kty.rawValue),  // Key type identifier
             -2: .byteString(x),             // X coordinate as byte string
             -3: .byteString(y)              // Y coordinate as byte string
        ]
        return cbor
    }
}

extension CoseKey: CBORDecodable {
    // Initializes a CoseKey from a CBOR object
    public init?(cbor obj: CBOR) {
        guard
            let calg = obj[-1], case let CBOR.unsignedInt(ralg) = calg, let alg = ECCurveName(rawValue: ralg),
            let ckty = obj[1], case let CBOR.unsignedInt(rkty) = ckty, let keyType = ECCurveType(rawValue: rkty),
            let cx = obj[-2], case let CBOR.byteString(rx) = cx,
            let cy = obj[-3], case let CBOR.byteString(ry) = cy
        else {
            return nil // Return nil if any of the expected values are missing or incorrect
        }
        
        crv = alg // Set curve name
        kty = keyType // Set key type
        x = rx // Set X coordinate
        y = ry // Set Y coordinate
    }
}

extension CoseKey {
    // Initializes a CoseKey from an elliptic curve name and an x9.63 representation
    public init(crv: ECCurveName, x963Representation: Data) {
        let keyData = x963Representation.dropFirst().bytes // Drop the first byte (0x04) which indicates uncompressed form
        let count = keyData.count / 2 // Split the keyData into X and Y coordinates
        self.init(x: Array(keyData[0..<count]), y: Array(keyData[count...]), crv: crv)
    }
    
    // Initializes a CoseKey from X and Y coordinates and a curve name (default is P-256)
    public init(x: [UInt8], y: [UInt8], crv: ECCurveName = .p256) {
        self.crv = crv // Set curve name
        self.x = x // Set X coordinate
        self.y = y // Set Y coordinate
        self.kty = crv.keyType // Set key type based on the curve
    }
    
    /// An ANSI x9.63 representation of the public key.
    /// The representation includes a 0x04 prefix followed by the X and Y coordinates.
    public func getx963Representation() -> Data {
        var keyData = Data([0x04]) // Start with the prefix indicating uncompressed form
        keyData.append(contentsOf: x) // Append X coordinate
        keyData.append(contentsOf: y) // Append Y coordinate
        return keyData
    }
}
