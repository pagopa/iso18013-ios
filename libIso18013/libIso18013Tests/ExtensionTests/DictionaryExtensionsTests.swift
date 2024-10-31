//
//  DictionaryExtensionsTests.swift
//  libIso18013
//
//  Created by Martina D'urso on 30/10/24.
//


import XCTest
@testable import libIso18013

class DictionaryExtensionsTests: XCTestCase {
    
    func testGetInnerValue() {
        let dictionary: [String: Any] = [
            "level1": [
                "level2": [
                    "level3": "finalValue"
                ]
            ]
        ]
        let value = dictionary.getInnerValue("level1.level2.level3")
        XCTAssertEqual(value, "finalValue")
    }
    
    func testGetInnerValueWithInvalidPath() {
        let dictionary: [String: Any] = [
            "level1": [
                "level2": [
                    "level3": "finalValue"
                ]
            ]
        ]
        let value = dictionary.getInnerValue("level1.level4")
        XCTAssertEqual(value, "")
    }
    
    func testDecodeJSON() {
        let dictionary: [String: Any] = [
            "name": "John",
            "age": 30
        ]
        
        struct Person: Decodable {
            let name: String
            let age: Int
        }
        
        let person = dictionary.decodeJSON(type: Person.self)
        XCTAssertNotNil(person)
        XCTAssertEqual(person?.name, "John")
        XCTAssertEqual(person?.age, 30)
    }
    
    func testStringSubscript() {
        let dictionary: [String: Any] = [
            "key": "value"
        ]
        
        enum TestKey: String {
            case key
        }
        
        XCTAssertEqual(dictionary[TestKey.key], "value")
    }
}
