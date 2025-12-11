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
    
    func testGenerateEmptyDeviceResponse() {
        
        guard let documentData: [UInt8] = Data(base64Encoded: DocumentTestData.issuerSignedDocument1)?.bytes else {
            XCTFail("document data must be valid")
            return
        }
        
        guard let deviceKeyRaw: [UInt8] = Data(base64Encoded: DocumentTestData.devicePrivateKey)?.bytes else {
            XCTFail("device key must be valid")
            return
        }
        
        guard let document = ProximityDocument(docType: DocType.euPid.rawValue, issuerSigned: documentData, deviceKeyRaw: deviceKeyRaw) else {
            XCTFail("document must be valid")
            return
        }
        
        let documents: [ProximityDocument] = [
            document
        ]
        
        
        let items: [String: [String: [String: Bool]]] = [
            "eu.europa.ec.eudi.pid.1": [
                :
            ]
        ]
        
       let sessionTranscript = Proximity.shared.generateOID4VPSessionTranscriptCBOR(clientId: "clientId", responseUri: "responseUri", authorizationRequestNonce: "authorizationRequestNonce", jwkThumbprint: "jwkThumbprint")
        
        guard let deviceResponseRaw = try? Proximity.shared.generateDeviceResponse(items: items, documents: documents, sessionTranscript: sessionTranscript) else {
            XCTFail("deviceResponse must be valid")
            return
        }
        
        print(Data(deviceResponseRaw).base64EncodedString())
        
        guard let deviceResponse = DeviceResponse(data: deviceResponseRaw) else {
            XCTFail("deviceResponse must be valid")
            return
        }
        
        let deviceResponseItems = deviceResponse.documents?.map({
            doc in
            return doc.issuerSigned.issuerNameSpaces?.nameSpaces.map({
                key, value in
                return value.map({$0.elementIdentifier})
            })
        }).reduce([], {
            return $0 + ($1 ?? [])
        }).reduce([], {
            return $0 + $1
        }) ?? []
        
        let deviceResponseErrorItems = deviceResponse.documents?.map({
            doc in
            return doc.errors?.errors.map({
                key, value in
                return value.map({$0.key})
            })
        }).reduce([], {
            return $0 + ($1 ?? [])
        }).reduce([], {
            return $0 + $1
        }) ?? []
        
        //ensure each requested item is contained in deviceResponse valid items or error items
        items.reduce([], { $0 + $1.value.reduce([], { $0 + $1.value.map({$0.key}) })})
            .forEach({
                item in
                XCTAssert(deviceResponseItems.contains(item) || deviceResponseErrorItems.contains(item))
        })
    }
    
    func testGenerateDeviceResponse() {
        
        guard let documentData: [UInt8] = Data(base64Encoded: DocumentTestData.issuerSignedDocument1)?.bytes else {
            XCTFail("document data must be valid")
            return
        }
        
        guard let deviceKeyRaw: [UInt8] = Data(base64Encoded: DocumentTestData.devicePrivateKey)?.bytes else {
            XCTFail("device key must be valid")
            return
        }
        
        guard let document = ProximityDocument(docType: DocType.euPid.rawValue, issuerSigned: documentData, deviceKeyRaw: deviceKeyRaw) else {
            XCTFail("document must be valid")
            return
        }
        
        let documents: [ProximityDocument] = [
            document
        ]
        
        
        let items = [
            "eu.europa.ec.eudi.pid.1": [
                "eu.europa.ec.eudi.pid.1" :
                    [
                        "birth_country": true,
                        "given_name_birth": true,
                        "birth_state": true,
                        "family_name": true,
                        "resident_postal_code": true,
                        "birth_date": true,
                        "resident_city": true,
                        "issuing_authority": true,
                        "nationality": true,
                        "document_number": true,
                        "resident_street": true,
                        "issuing_jurisdiction": true,
                        "given_name": true,
                        "age_in_years": true,
                        "family_name_birth": true,
                        "issuing_country": true,
                        "portrait": true,
                        "expiry_date": true,
                        "administrative_number": true,
                        "issuance_date": true,
                        "resident_state": true,
                        "gender": true,
                        "age_birth_year": true,
                        "portrait_capture_date": true,
                        "resident_house_number": true,
                        "birth_place": true,
                        "resident_address": true,
                        "resident_country": true,
                        "birth_city": true
                    ]
            ]
        ]
        
       let sessionTranscript = Proximity.shared.generateOID4VPSessionTranscriptCBOR(clientId: "clientId", responseUri: "responseUri", authorizationRequestNonce: "authorizationRequestNonce", jwkThumbprint: "jwkThumbprint")
        
        
        
        guard let deviceResponseRaw = try? Proximity.shared.generateDeviceResponse(items: items, documents: documents, sessionTranscript: sessionTranscript) else {
            XCTFail("deviceResponse must be valid")
            return
        }
        
        guard let deviceResponse = DeviceResponse(data: deviceResponseRaw) else {
            XCTFail("deviceResponse must be valid")
            return
        }
        
        let deviceResponseItems = deviceResponse.documents?.map({
            doc in
            return doc.issuerSigned.issuerNameSpaces?.nameSpaces.map({
                key, value in
                return value.map({$0.elementIdentifier})
            })
        }).reduce([], {
            return $0 + ($1 ?? [])
        }).reduce([], {
            return $0 + $1
        }) ?? []
        
        let deviceResponseErrorItems = deviceResponse.documents?.map({
            doc in
            return doc.errors?.errors.map({
                key, value in
                return value.map({$0.key})
            })
        }).reduce([], {
            return $0 + ($1 ?? [])
        }).reduce([], {
            return $0 + $1
        }) ?? []
        
        //ensure each requested item is contained in deviceResponse valid items or error items
        items.reduce([], { $0 + $1.value.reduce([], { $0 + $1.value.map({$0.key}) })})
            .forEach({
                item in
                XCTAssert(deviceResponseItems.contains(item) || deviceResponseErrorItems.contains(item))
        })
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
