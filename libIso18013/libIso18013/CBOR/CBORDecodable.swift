//
//  CBORDecodable.swift
//  libIso18013
//
//  Created by Antonio on 02/10/24.
//

import SwiftCBOR

public protocol CBORDecodable {
  init?(cbor: CBOR)
}

extension CBORDecodable {
  public init?(data: [UInt8]) {
    guard let decodedObject = try? CBOR.decode(data) else { return nil }
    self.init(cbor: decodedObject)
  }
}
