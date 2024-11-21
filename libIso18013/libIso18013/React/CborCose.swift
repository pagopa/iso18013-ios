//
//  CborCose.swift
//  libIso18013
//
//  Created by Antonio on 15/11/24.
//

import SwiftCBOR
import OrderedCollections

public class CborCose {
    
    public static func decodeCBOR(data: Data, _ documents: Bool = true) -> String? {
        guard let cborObject = try? CBOR.decode(data.bytes) else {
            return nil
        }
        
        guard let jsonObject = cborToJson(cborObject: cborObject) else {
            return nil
        }
        
        let data: Data
        
        if documents {
            
            let documents = ["documents": [jsonObject]]
            
            guard let jsonData = try? JSONSerialization.data(withJSONObject: documents, options: []) else {
                return nil
            }
            
            data = jsonData
        }
        else {
            guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: []) else {
                return nil
            }
            
            data = jsonData
        }
        
        return String(data: data, encoding: String.Encoding.utf8)
    }
    
    public static func jsonFromCBOR(data: Data) -> Any? {
        guard let cborObject = try? CBOR.decode(data.bytes) else {
            return nil
        }
        
        guard let jsonObject = cborToJson(cborObject: cborObject) else {
            return nil
        }
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: []) else {
            return nil
        }
        
        return try? JSONSerialization.jsonObject(with: jsonData)
    }
    
    
    private static func issuerItemToJson(itemMap: OrderedDictionary<CBOR, CBOR>) -> [AnyHashable?: AnyHashable?]? {
        if let elementIdentifier = itemMap[CBOR.utf8String("elementIdentifier")],
           let elementValue = itemMap[CBOR.utf8String("elementValue")],
           let digestID = itemMap[CBOR.utf8String("digestID")],
           let random =  itemMap[CBOR.utf8String("random")] {
            return [
                "digestID": cborToJson(cborObject: digestID, isKey: true) ,
                "random": cborToJson(cborObject: random, isKey: true) ,
                cborToJson(cborObject: elementIdentifier, isKey: true) : cborToJson(cborObject: elementValue, isKey: true)
            ]
        }
        return nil
    }
    
    private static func cborToJson(cborObject: CBOR?,
                            isKey: Bool = false,
                            isCBOR: Bool = false) -> AnyHashable? {
        
        switch(cborObject) {
            case .map(let cborMap):
                var map: [AnyHashable?: AnyHashable?] = [:]
                
                if let issuerItem = issuerItemToJson(itemMap: cborMap) {
                    map = issuerItem
                }
                else {
                    
                    cborMap.keys.forEach({
                        key in
                        map[cborToJson(cborObject: key, isKey: true)] = cborToJson(cborObject: cborMap[key],
                                                                                   isKey: isKey)
                    })
                }
                return map as AnyHashable
                
            case .array(let cborArray):
                var array: [AnyHashable?] = []
                array = cborArray.map({
                    value in
                    cborToJson(cborObject: value, isKey: isKey)
                })
                return array as AnyHashable
                
            case .byteString(let bytes):
                if isCBOR, let cbor = try? CBOR.decode(bytes) {
                    return cborToJson(cborObject: cbor, isKey: isKey)
                }
                return Data(bytes).base64EncodedString()
                
            case .tagged(let tag, let cbor):
                if tag.rawValue == 24 {
                    return cborToJson(cborObject: cbor, isKey: isKey, isCBOR: true)
                }
                if tag.rawValue == 1004 {
                    return cborToJson(cborObject: cbor, isKey: isKey, isCBOR: true)
                }
                return [
                    "\(tag.rawValue)" : cborToJson(cborObject: cbor, isKey: isKey, isCBOR: tag.rawValue == 24)
                ]
                
            default:
                if isKey {
                    return "\(cborObject!.unwrap()!)"
                }
                else {
                    return cborObject?.unwrap() as? AnyHashable
                }
        }
        
    }
    
    
    public static func sign(data: Data, privateKey: CoseKeyPrivate) -> Data {
        
        let cose = try! Cose.makeCoseSign1(payloadData: data, deviceKey: privateKey, alg: .es256)
        
        return Data(cose.encode(options: CBOROptions()))
    }
    
    public static func verify(data: Data, publicKey: CoseKey) -> Bool {
        
        let coseCBOR = try? CBOR.decode(data.bytes)
        
        let cose = Cose.init(type: .sign1, cbor: coseCBOR!)!
        
        return (try? cose.validateCoseSign1(publicKey_x963: publicKey.getx963Representation())) ?? false
    }
    
}
