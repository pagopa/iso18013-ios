//
//  Array+.swift
//  libIso18013
//
//  Created by Antonio on 02/10/24.
//

import SwiftCBOR
import OrderedCollections


extension Array where Element == IssuerSignedItem {
	public func findItem(name: String) -> IssuerSignedItem? { first(where: { $0.elementIdentifier == name} ) }
	public func findMap(name: String) -> OrderedDictionary<CBOR, CBOR>? { first(where: { $0.elementIdentifier == name} )?.getTypedValue() }
	public func findArray(name: String) -> [CBOR]? { first(where: { $0.elementIdentifier == name} )?.getTypedValue() }
	public func toJson(base64: Bool = false) -> OrderedDictionary<String, Any> {
		CBOR.decodeDictionary(OrderedDictionary(grouping: self, by: { CBOR.utf8String($0.elementIdentifier) }).mapValues { $0.first!.elementValue }, base64: base64)
	}
}
