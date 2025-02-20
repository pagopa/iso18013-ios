//
//  UInt8ArrayExtensionsTests.swift
//  libIso18013
//
//  Created by Martina D'urso on 18/10/24.
//


import XCTest
internal import SwiftCBOR
internal import OrderedCollections
@testable import IOWalletProximity

class IssuerSignedItemArrayTests: XCTestCase {
    
    func testFindItem() {
        let item1 = IssuerSignedItem(digestID: 1, random: [0x01, 0x02], elementIdentifier: "item1", elementValue: .utf8String("value1"), rawData: nil)
        let item2 = IssuerSignedItem(digestID: 2, random: [0x03, 0x04], elementIdentifier: "item2", elementValue: .utf8String("value2"), rawData: nil)
        let items = [item1, item2]
        
        let foundItem = items.findItem(name: "item1")
        XCTAssertNotNil(foundItem)
        XCTAssertEqual(foundItem?.elementIdentifier, "item1")
        XCTAssertEqual(foundItem?.elementValue, .utf8String("value1"))
    }
    
    func testFindItemNotFound() {
        let item1 = IssuerSignedItem(digestID: 1, random: [0x01, 0x02], elementIdentifier: "item1", elementValue: .utf8String("value1"), rawData: nil)
        let items = [item1]
        
        let foundItem = items.findItem(name: "item2")
        XCTAssertNil(foundItem, "Item with identifier 'item2' should not be found")
    }
    
    func testFindMap() {
        let mapValue: OrderedDictionary<CBOR, CBOR> = [
            .utf8String("key1"): .utf8String("value1"),
            .utf8String("key2"): .utf8String("value2")
        ]
        let item = IssuerSignedItem(digestID: 1, random: [0x01, 0x02], elementIdentifier: "item1", elementValue: .map(mapValue), rawData: nil)
        let items = [item]
        
        let foundMap = items.findMap(name: "item1")
        XCTAssertNotNil(foundMap)
        XCTAssertEqual(foundMap?[.utf8String("key1")], .utf8String("value1"))
        XCTAssertEqual(foundMap?[.utf8String("key2")], .utf8String("value2"))
    }
    
    func testFindArray() {
        let arrayValue: [CBOR] = [.utf8String("value1"), .utf8String("value2")]
        let item = IssuerSignedItem(digestID: 1, random: [0x01, 0x02], elementIdentifier: "item1", elementValue: .array(arrayValue), rawData: nil)
        let items = [item]
        
        let foundArray = items.findArray(name: "item1")
        XCTAssertNotNil(foundArray)
        XCTAssertEqual(foundArray?.count, 2)
        XCTAssertEqual(foundArray?[0], .utf8String("value1"))
        XCTAssertEqual(foundArray?[1], .utf8String("value2"))
    }
    
    func testToJson() {
        let item1 = IssuerSignedItem(digestID: 1, random: [0x01, 0x02], elementIdentifier: "item1", elementValue: .utf8String("value1"), rawData: nil)
        let item2 = IssuerSignedItem(digestID: 2, random: [0x03, 0x04], elementIdentifier: "item2", elementValue: .utf8String("value2"), rawData: nil)
        let items = [item1, item2]
        
        let json = items.toJson()
        XCTAssertEqual(json["item1"] as? String, "value1")
        XCTAssertEqual(json["item2"] as? String, "value2")
    }
}

class UInt8ArrayExtensionsTests: XCTestCase {
    
    func testHex() {
        let byteArray: [UInt8] = [0x1A, 0x2B, 0x3C]
        let hexString = byteArray.hex
        XCTAssertEqual(hexString, "1A2B3C", "Byte array should be correctly converted to hex string")
    }
    
    func testTaggedEncoded() {
        let byteArray: [UInt8] = [0x01, 0x02, 0x03]
        let cbor = byteArray.taggedEncoded
        
        if case let .tagged(tag, value) = cbor {
            XCTAssertEqual(tag.rawValue, CBOR.Tag.encodedCBORDataItem.rawValue, "Tag should be .encodedCBORDataItem")
            XCTAssertEqual(value, .byteString(byteArray), "CBOR value should be the byte string")
        } else {
            XCTFail("Failed to encode byte array as tagged CBOR value")
        }
    }
}
