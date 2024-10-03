//
//  IssuerNameSpaces.swift
//  libIso18013
//
//  Created by Antonio on 02/10/24.
//

import Foundation
import SwiftCBOR
import OrderedCollections

public struct IssuerNameSpaces {
  
  public let nameSpaces: [String: [IssuerSignedItem]]
  public subscript(nameSpace: String) -> [IssuerSignedItem]? { nameSpaces[nameSpace] }
  
  public init(nameSpaces: [String: [IssuerSignedItem]]) {
    self.nameSpaces = nameSpaces
  }
}

extension IssuerNameSpaces: CBORDecodable {
  public init?(cbor: CBOR) {
    
    guard case let .map(cborMap) = cbor else {
      return nil
    }
    
    var nameSpaces = [String: [IssuerSignedItem]]()
    
    for (key,value) in cborMap {
      guard case let .utf8String(nameSpace) = key,
            case let .array(cborItems) = value else {
        continue
      }
      let items = cborItems.compactMap { cborItem -> IssuerSignedItem? in
        guard case let .tagged(itemTag, itemDataCbor) = cborItem,
              itemTag == .encodedCBORDataItem,
              case let .byteString(issuerSignedItemData) = itemDataCbor,
              let issuerSignedItem = IssuerSignedItem(data: issuerSignedItemData) else {
          return nil
        }
        return issuerSignedItem
      }
      nameSpaces[nameSpace] = items
    }
    
    guard nameSpaces.count > 0 else {
      return nil
    }
    
    self.nameSpaces = nameSpaces
  }
}

extension IssuerNameSpaces: CBOREncodable {
  public func toCBOR(options: CBOROptions) -> CBOR {
    var cborMap = OrderedDictionary<CBOR, CBOR>()
    for (nameSpace, items) in nameSpaces {
      cborMap[.utf8String(nameSpace)] = .array(items.map {
        .tagged(.encodedCBORDataItem, .byteString($0.encode(options: options)))
      })
    }
    return .map(cborMap)
  }
}
