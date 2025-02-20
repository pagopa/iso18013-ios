//
//  NameValueTests.swift
//  libIso18013
//
//  Created by Martina D'urso on 30/10/24.
//


import XCTest

@testable import IOWalletProximity

class NameValueTests: XCTestCase {
    func testNameValue_Initialization() {
        let name = "TestName"
        let value = "TestValue"
        let nameSpace = "TestNamespace"
        let order = 1
        let children = [NameValue(name: "ChildName", value: "ChildValue")]
        
        let nameValue = NameValue(name: name, value: value, nameSpace: nameSpace, order: order, children: children)
        
        XCTAssertEqual(nameValue.name, name, "Name was not set correctly")
        XCTAssertEqual(nameValue.value, value, "Value was not set correctly")
        XCTAssertEqual(nameValue.nameSpace, nameSpace, "Namespace was not set correctly")
        XCTAssertEqual(nameValue.order, order, "Order was not set correctly")
        XCTAssertEqual(nameValue.children?.count, 1, "Children were not set correctly")
        XCTAssertEqual(nameValue.children?.first?.name, "ChildName", "Child name was not set correctly")
    }
    
    func testNameValue_AddChild() {
        var nameValue = NameValue(name: "Parent", value: "ParentValue")
        let child = NameValue(name: "Child", value: "ChildValue")
        
        nameValue.add(child: child)
        
        XCTAssertNotNil(nameValue.children, "Children should not be nil after adding a child")
        XCTAssertEqual(nameValue.children?.count, 1, "Children count should be 1 after adding a child")
        XCTAssertEqual(nameValue.children?.first?.name, "Child", "Child name was not set correctly")
    }
}

class NameImageTests: XCTestCase {
    func testNameImage_Initialization() {
        let name = "TestName"
        let imageData = Data([0x00, 0x01, 0x02, 0x03])
        let nameSpace = "TestNamespace"
        
        let nameImage = NameImage(name: name, image: imageData, nameSpace: nameSpace)
        
        XCTAssertEqual(nameImage.name, name, "Name was not set correctly")
        XCTAssertEqual(nameImage.image, imageData, "Image data was not set correctly")
        XCTAssertEqual(nameImage.nameSpace, nameSpace, "Namespace was not set correctly")
    }
}
