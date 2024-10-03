//
//  Document.swift
//  libIso18013
//
//  Created by Antonio on 02/10/24.
//


import Foundation
import SwiftCBOR
import OrderedCollections

public struct Document {
  
  public let docType: String
  public let issuerSigned: IssuerSigned
  public let errors: Errors?
  
  enum Keys:String {
    case docType
    case issuerSigned
    case deviceSigned
    case errors
  }
  
  public init(docType: String, issuerSigned: IssuerSigned, errors: Errors? = nil) {
    self.docType = docType
    self.issuerSigned = issuerSigned
    self.errors = errors
  }
}

extension Document: CBORDecodable {
  public init?(cbor: CBOR) {
    
    guard case .map(let cborMap) = cbor else {
      return nil
    }
    
    guard case .utf8String(let docType) = cborMap[Keys.docType] else {
      return nil
    }
    
    self.docType = docType
    
    guard let cborIssuerSigned = cborMap[Keys.issuerSigned],
            let issuerSigned = IssuerSigned(cbor: cborIssuerSigned) else {
      return nil
    }
    self.issuerSigned = issuerSigned
    
    if let cborErrors = cborMap[Keys.errors],
       let errors = Errors(cbor: cborErrors) {
      self.errors = errors
    } else {
      self.errors = nil
    }
  }
}

extension Document: CBOREncodable {
  public func toCBOR(options: CBOROptions) -> CBOR {
    var cbor = OrderedDictionary<CBOR, CBOR>()
    cbor[.utf8String(Keys.docType.rawValue)] = .utf8String(docType)
    cbor[.utf8String(Keys.issuerSigned.rawValue)] = issuerSigned.toCBOR(options: options)
    if let errors { cbor[.utf8String(Keys.errors.rawValue)] = errors.toCBOR(options: options) }
    return .map(cbor)
  }
}
