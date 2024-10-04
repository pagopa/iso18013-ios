//
//  Array+.swift
//  libIso18013
//
//  Created by Antonio on 02/10/24.
//

import SwiftCBOR
import OrderedCollections

// Extension for arrays of IssuerSignedItem to add utility functions for finding items and converting to JSON
extension Array where Element == IssuerSignedItem {
    
    // Find the first IssuerSignedItem in the array with a matching element identifier
    // - Parameter name: The identifier of the item to find
    // - Returns: The first matching IssuerSignedItem, or nil if not found
    public func findItem(name: String) -> IssuerSignedItem? {
        return first(where: { $0.elementIdentifier == name })
    }
    
    // Find the first IssuerSignedItem in the array with a matching element identifier and return its value as a map (OrderedDictionary)
    // - Parameter name: The identifier of the item to find
    // - Returns: The value of the item as an OrderedDictionary, or nil if not found
    public func findMap(name: String) -> OrderedDictionary<CBOR, CBOR>? {
        return first(where: { $0.elementIdentifier == name })?.getTypedValue()
    }
    
    // Find the first IssuerSignedItem in the array with a matching element identifier and return its value as an array of CBOR
    // - Parameter name: The identifier of the item to find
    // - Returns: The value of the item as an array of CBOR, or nil if not found
    public func findArray(name: String) -> [CBOR]? {
        return first(where: { $0.elementIdentifier == name })?.getTypedValue()
    }
    
    // Convert the array of IssuerSignedItem to a JSON-compatible OrderedDictionary
    // - Parameter base64: Boolean flag indicating whether byte strings should be encoded as Base64
    // - Returns: An OrderedDictionary where the keys are element identifiers and the values are their corresponding CBOR-encoded values
    public func toJson(base64: Bool = false) -> OrderedDictionary<String, Any> {
        // Group the array by element identifier and map the values to their CBOR element values
        let groupedItems = OrderedDictionary(grouping: self, by: { CBOR.utf8String($0.elementIdentifier) })
            .mapValues { $0.first!.elementValue }
        
        // Decode the grouped items as a JSON-compatible dictionary
        return CBOR.decodeDictionary(groupedItems, base64: base64)
    }
}

