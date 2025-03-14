////
////  ManageNameSpaces.swift
////  IOWalletProximityExample
////
////  Created by Martina D'urso on 07/10/24.
////
//
//import Foundation
//import SwiftCBOR
//import IOWalletProximity
//
//class ManageNameSpaces {
//    
//    // Method to extract a display string or an image from a CBOR value
//    static func extractDisplayStringOrImage(
//        _ name: String,
//        _ cborValue: CBOR,
//        _ displayImages: inout [NameImage],
//        _ ns: String,
//        _ order: Int
//    ) -> NameValue? {
//        // Use the normal description of the CBOR value
//        var value = cborValue.description
//        var dataType = cborValue.mdocDataType
//        
//        // If the name is "sex" and the value is 1 or 2, translate it to "male" or "female"
//        if name == "sex", let isex = Int(value), isex <= 2 {
//            value = NSLocalizedString(isex == 1 ? "male" : "female", comment: "")
//            dataType = .string
//        }
//        
//        // Handle CBOR values of type byteString
//        if case let .byteString(byteString) = cborValue {
//            if name == "user_pseudonym" {
//                // If the name is "user_pseudonym", encode the value in base64
//                value = Data(byteString).base64EncodedString()
//            } else {
//                // Otherwise, add the image to the displayImages array and return nil
//                displayImages.append(NameImage(name: name, image: Data(byteString), nameSpace: ns))
//                return nil
//            }
//        }
//        
//        // Create a NameValue node with the extracted information
//        var node = NameValue(name: name, value: value, nameSpace: ns, mdocDataType: dataType, order: order)
//        
//        // If the CBOR value is a map, decode it and add child nodes recursively
//        if case let .map(map) = cborValue {
//            let innerJsonMap = CBOR.decodeDictionary(map, unwrap: false)
//            for (innerOrder, (key, value)) in innerJsonMap.enumerated() {
//                guard let childValue = value as? CBOR else { continue }
//                if let childNode = extractDisplayStringOrImage(key, childValue, &displayImages, ns, innerOrder) {
//                    node.add(child: childNode)
//                }
//            }
//            // If the CBOR value is an array, decode it and add child nodes recursively
//        } else if case let .array(array) = cborValue {
//            let innerJsonArray = CBOR.decodeList(array, unwrap: false)
//            for (innerOrder, value) in innerJsonArray.enumerated() {
//                guard let childValue = value as? CBOR else { continue }
//                let key = "\(name)[\(innerOrder)]"
//                if let childNode = extractDisplayStringOrImage(key, childValue, &displayImages, ns, innerOrder) {
//                    node.add(child: childNode)
//                }
//            }
//        }
//        
//        // Return the NameValue node
//        return node
//    }
//    
//    // Method to extract display strings from a dictionary of namespaces
//    static func extractDisplayStrings(
//        _ nameSpaces: [String: [IssuerSignedItem]],
//        _ displayStrings: inout [NameValue],
//        _ displayImages: inout [NameImage]
//    ) {
//        var order = 0
//        
//        // Iterate over each namespace and its items
//        for (namespace, items) in nameSpaces {
//            for item in items {
//                // Extract the item's information and, if it's not an image, add it to the displayStrings array
//                if let extractedValue = extractDisplayStringOrImage(item.elementIdentifier, item.elementValue, &displayImages, namespace, order) {
//                    displayStrings.append(extractedValue)
//                    order += 1
//                }
//            }
//        }
//    }
//    
//    // Method to get signed items from the issuer
//    static func getSignedItems(
//        _ issuerSigned: IssuerSigned,
//        _ docType: String,
//        _ namespaces: [String]? = nil
//    ) -> [String: [IssuerSignedItem]]? {
//        // Get the namespaces from the issuerSigned object
//        guard var nameSpaces = issuerSigned.issuerNameSpaces?.nameSpaces else { return nil }
//        
//        // If a namespace filter is provided, apply the filter
//        if let namespaces = namespaces {
//            nameSpaces = nameSpaces.filter { namespaces.contains($0.key) }
//        }
//        
//        // Return the filtered namespaces
//        return nameSpaces
//    }
//}
