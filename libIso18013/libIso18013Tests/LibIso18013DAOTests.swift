//
//  LibIso18013DAOTests.swift
//  libIso18013
//
//  Created by Antonio on 10/10/24.
//

import XCTest
import SwiftCBOR
@testable import libIso18013

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
                documentName: documentName,
                curve: .p256,
                forceSecureEnclave: true)
            
            assert(unsigned.document == nil)
            assert(unsigned.docType == DocType.mDL.rawValue)
            assert(unsigned.name == documentName)
        }
        catch  {
            print(error.localizedDescription)
            assert(false)
        }
    }
    
    func doTestStoreDocument(dao: LibIso18013DAOProtocol) {
        let documentName = "Patente"
        guard let documentData = Data(base64Encoded: DocumentTestData.issuerSignedDocument1) else {
            assert(false)
        }
        
        do {
            
            guard let deviceKey = CoseKeyPrivate(base64: DocumentTestData.devicePrivateKey) else {
                assert(false)
            }
            
            let unsigned = try dao.createDocument(docType: DocType.mDL.rawValue, documentName: documentName, deviceKey: deviceKey)
            
            let issuedIdentifier = try dao.storeDocument(identifier: unsigned.identifier, documentData: documentData)
            
            let issued = try dao.getDocumentByIdentifier(identifier: issuedIdentifier)
            
            
            assert(unsigned.document == nil)
            assert(unsigned.docType == issued.docType)
            assert(unsigned.name == issued.name)
            assert(issued.document != nil)
            
        }
        catch  {
            print(error.localizedDescription)
            assert(false)
        }
    }
}
