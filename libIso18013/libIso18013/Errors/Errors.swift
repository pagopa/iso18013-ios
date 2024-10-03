//
//  Errors.swift
//  libIso18013
//
//  Created by Antonio on 02/10/24.
//

import Foundation
import SwiftCBOR
import OrderedCollections

public typealias ErrorItems = [String: UInt64]

public struct Errors {
  
  public let errors: [String: ErrorItems]
  public subscript(nameSpace: String) -> ErrorItems? { errors[nameSpace] }
  
  public init(errors: [String : ErrorItems]) {
    self.errors = errors
  }
}

extension Errors: CBORDecodable {
  public init?(cbor: CBOR) {
    guard case let .map(errors) = cbor else {
      return nil
    }
    if errors.count == 0 {
      return nil
    }
    let pairs = errors.compactMap {
      (errorNameSpace: CBOR, errorItemsValue: CBOR) -> (String, ErrorItems)? in
      guard case .utf8String(let nameSpace) = errorNameSpace else {
        return nil
      }
      guard case .map(let errorItemsMap) = errorItemsValue else {
        return nil
      }
      let errorItems = errorItemsMap.compactMap {
        (errorItemKey: CBOR, errorItemValue: CBOR) -> (String, UInt64)?  in
        guard case .utf8String(let errorItemDescription) = errorItemKey else {
          return nil
        }
        guard case .unsignedInt(let errorItemCode) = errorItemValue else {
          return nil
        }
        return (errorItemDescription, errorItemCode)
      }
      let errorItemsDictionary = Dictionary(errorItems, uniquingKeysWith: {
        (first, _) in first })
      if errorItemsDictionary.count == 0 {
        return nil
      }
      return (nameSpace, errorItemsDictionary)
    }
    self.errors = Dictionary(pairs, uniquingKeysWith: { (first, _) in first })
  }
}

extension Errors: CBOREncodable {
  public func toCBOR(options: CBOROptions) -> CBOR {
    let map1 = errors.map {
      (nameSpace: String, errorItems: ErrorItems) -> (CBOR, CBOR) in
      let kns = CBOR.utf8String(nameSpace)
      let mei = errorItems.map { (dei: String, ec: UInt64) -> (CBOR, CBOR) in
        (.utf8String(dei), .unsignedInt(ec))
      }
      return (kns, .map(OrderedDictionary(mei, uniquingKeysWith: { (d, _) in d })))
    }
    let cborMap = OrderedDictionary(map1, uniquingKeysWith: { (ns, _) in ns })
    return .map(cborMap)
  }
}

