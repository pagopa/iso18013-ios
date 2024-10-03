//
//  CBOREncodable.swift
//  libIso18013
//
//  Created by Antonio on 02/10/24.
//

import SwiftCBOR

extension CBOREncodable {
  public func encode(options: SwiftCBOR.CBOROptions) -> [UInt8] {
    toCBOR(options: CBOROptions()).encode()
  }
  public var taggedEncoded: CBOR {
    CBOR.tagged(.encodedCBORDataItem, .byteString(CBOR.encode(self)))
  }
}
