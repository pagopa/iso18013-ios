//
//  LibIso18013DAOTests.swift
//  libIso18013
//
//  Created by Antonio on 10/10/24.
//

import XCTest
internal import SwiftCBOR
@testable import IOWalletProximity

final class LibIso18013DAOTests: XCTestCase {
    
    func testCreateDocumentMemory() {
        doTestCreateDocument(dao: LibIso18013DAOMemory())
    }
    
    func testStoreDocumentMemory() {
        doTestStoreDocument(dao: LibIso18013DAOMemory())
    }
    
    func doTestCreateDocument(dao: LibIso18013DAOProtocol) {
        let documentName = "Patente"
        
        do {
        
            let unsigned = try dao.createDocument(
                docType: DocType.mDL.rawValue,
                documentName: documentName)
            
            XCTAssert(unsigned.documentData == nil)
            XCTAssert(unsigned.docType == DocType.mDL.rawValue)
            XCTAssert(unsigned.name == documentName)
        }
        catch  {
            XCTFail(error.localizedDescription)
        }
    }
    
    func doTestStoreDocument(dao: LibIso18013DAOProtocol) {
        let documentName = "Patente"
        guard let documentData = Data(base64Encoded: DocumentTestData.issuerSignedDocument1) else {
            XCTFail("document data must be valid")
            return
        }
        
        do {
            
            guard let deviceKey = CoseKeyPrivate(base64: DocumentTestData.devicePrivateKey) else {
                XCTFail("device key must be valid")
                return
            }
            
            let unsigned = try dao.createDocument(docType: DocType.mDL.rawValue, documentName: documentName, deviceKeyData: deviceKey.encode(options: CBOROptions()))
            
            let issuedIdentifier = try dao.storeDocument(identifier: unsigned.identifier, documentData: documentData)
            
            let issued = try dao.getDocumentByIdentifier(identifier: issuedIdentifier)
            
            
            XCTAssert(unsigned.documentData == nil)
            XCTAssert(unsigned.docType == issued.docType)
            XCTAssert(unsigned.name == issued.name)
            XCTAssert(issued.documentData != nil)
            
        }
        catch  {
            XCTFail(error.localizedDescription)
        }
    }
}
