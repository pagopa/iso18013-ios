//
//  ManageNameSpaces.swift
//  libIso18013-example
//
//  Created by Martina D'urso on 07/10/24.
//

import Foundation
import SwiftCBOR
import libIso18013

class ManageNameSpaces {
    
    static func extractDisplayStringOrImage(_ name: String, _ cborValue: CBOR, _ bDebugDisplay: Bool, _ displayImages: inout [NameImage], _ ns: String, _ order: Int) -> NameValue {
        var value = bDebugDisplay ? cborValue.debugDescription : cborValue.description
        var dt = cborValue.mdocDataType
        if name == "sex", let isex = Int(value), isex <= 2 {
            value = NSLocalizedString(isex == 1 ? "male" : "female", comment: ""); dt = .string
        }
        if case let .byteString(bs) = cborValue {
            if name == "user_pseudonym" {
                value = Data(bs).base64EncodedString()
            } else {
                displayImages.append(NameImage(name: name, image: Data(bs), nameSpace: ns))
            }
        }
        var node = NameValue(name: name, value: value, nameSpace: ns, mdocDataType: dt, order: order)
        if case let .map(m) = cborValue {
            let innerJsonMap = CBOR.decodeDictionary(m, unwrap: false)
            for (o2,(k,v)) in innerJsonMap.enumerated() {
                guard let cv = v as? CBOR else { continue }
                node.add(child: extractDisplayStringOrImage(k, cv, bDebugDisplay, &displayImages, ns, o2))
            }
        } else if case let .array(a) = cborValue {
            let innerJsonArray = CBOR.decodeList(a, unwrap: false)
            for (o2,v) in innerJsonArray.enumerated() {
                guard let cv = v as? CBOR else { continue }
                let k = "\(name)[\(o2)]"
                node.add(child: extractDisplayStringOrImage(k, cv, bDebugDisplay, &displayImages, ns, o2))
            }
        }
        return node
    }
    
    static func extractDisplayStrings(_ nameSpaces: [String: [IssuerSignedItem]], _ displayStrings: inout [NameValue], _ displayImages: inout [NameImage]) {
        let bDebugDisplay = UserDefaults.standard.bool(forKey: "DebugDisplay")
        var order = 0
        for (ns,items) in nameSpaces {
            for item in items {
                let n = extractDisplayStringOrImage(item.elementIdentifier, item.elementValue, bDebugDisplay, &displayImages, ns, order)
                displayStrings.append(n)
                order = order + 1
            }
        }
    }
    
    static func getSignedItems(_ issuerSigned: IssuerSigned, _ docType: String, _ ns: [String]? = nil) -> [String: [IssuerSignedItem]]? {
        guard var nameSpaces = issuerSigned.issuerNameSpaces?.nameSpaces else { return nil }
        if let ns { nameSpaces = nameSpaces.filter { ns.contains($0.key) } }
        return nameSpaces
    }
    
}
