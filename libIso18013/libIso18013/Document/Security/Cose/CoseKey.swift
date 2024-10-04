//
//  CoseKey.swift
//  libIso18013
//
//  Created by Antonio on 03/10/24.
//

import SwiftCBOR

// Defined in RFC 8152
public struct CoseKey: Equatable {
  public let crv: ECCurveName
  var kty: ECCurveType
  let x: [UInt8]
  let y: [UInt8]
}

extension CoseKey: CBOREncodable {
  public func toCBOR(options: CBOROptions) -> CBOR {
    let cbor: CBOR = [
      -1: .unsignedInt(crv.rawValue), 1: .unsignedInt(kty.rawValue),
       -2: .byteString(x), -3: .byteString(y),
    ]
    return cbor
  }
}

extension CoseKey: CBORDecodable {
  public init?(cbor obj: CBOR) {
    guard let calg = obj[-1], case let CBOR.unsignedInt(ralg) = calg, let alg = ECCurveName(rawValue: ralg) else { return nil }
    crv = alg
    guard let ckty = obj[1], case let CBOR.unsignedInt(rkty) = ckty, let keyType = ECCurveType(rawValue: rkty) else { return nil }
    kty = keyType
    guard let cx = obj[-2], case let CBOR.byteString(rx) = cx else { return nil }
    x = rx
    guard let cy = obj[-3], case let CBOR.byteString(ry) = cy else { return nil }
    y = ry
  }
}

extension CoseKey {
  public init(crv: ECCurveName, x963Representation: Data) {
    let keyData = x963Representation.dropFirst().bytes
    let count = keyData.count/2
    self.init(x: Array(keyData[0..<count]), y: Array(keyData[count...]), crv: crv)
  }
  
  public init(x: [UInt8], y: [UInt8], crv: ECCurveName = .p256) {
    self.crv = crv
    self.x = x
    self.y = y
    self.kty = crv.keyType
  }
  /// An ANSI x9.63 representation of the public key.
  public func getx963Representation() -> Data {
    let keyData = NSMutableData(bytes: [0x04], length: [0x04].count)
    keyData.append(Data(x))
    keyData.append(Data(y))
    return keyData as Data
  }
}
