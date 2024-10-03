//
//  IssuerSigned.swift
//  libIso18013
//
//  Created by Antonio on 02/10/24.
//


import Foundation
import SwiftCBOR
import OrderedCollections

public struct IssuerSigned {
  public let issuerNameSpaces: IssuerNameSpaces?
  //MARK: implement IssuerAuth
  
  enum Keys: String {
    case nameSpaces
    case issuerAuth
  }
  
  public init(issuerNameSpaces: IssuerNameSpaces?) {
    self.issuerNameSpaces = issuerNameSpaces
  }
}

extension IssuerSigned: CBORDecodable {
  public init?(cbor: CBOR) {
    guard case let .map(cborMap) = cbor else {
      return nil
    }
    if let issuerNameSpaceCbor = cborMap[Keys.nameSpaces] {
      issuerNameSpaces = IssuerNameSpaces(cbor: issuerNameSpaceCbor)
    } else {
      issuerNameSpaces = nil
    }
  }
}

extension IssuerSigned: CBOREncodable {
  public func toCBOR(options: CBOROptions) -> CBOR {
    var cbor = OrderedDictionary<CBOR, CBOR>()
    
    if let issuerNameSpaces = issuerNameSpaces {
      cbor[.utf8String(Keys.nameSpaces.rawValue)] = issuerNameSpaces.toCBOR(options: options)
    }
    
    return .map(cbor)
  }
}


