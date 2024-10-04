//
//  CBOREncodable.swift
//  libIso18013
//
//  Created by Antonio on 02/10/24.
//

import SwiftCBOR

// Extension for types that conform to CBOREncodable, providing default encoding functionality
extension CBOREncodable {
    
    // Function to encode the object into a CBOR byte array
    // - Parameter options: Options for encoding CBOR
    // - Returns: An array of bytes representing the encoded CBOR object
    public func encode(options: SwiftCBOR.CBOROptions) -> [UInt8] {
        return toCBOR(options: options).encode()
    }
    
    // A computed property that returns the object as a tagged CBOR value
    // - Returns: A tagged CBOR value where the object is encoded as a byte string
    public var taggedEncoded: CBOR {
        return CBOR.tagged(.encodedCBORDataItem, .byteString(CBOR.encode(self)))
    }
}
