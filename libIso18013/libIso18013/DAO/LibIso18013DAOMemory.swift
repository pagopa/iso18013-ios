//
//  LibIso18013DAOMemory.swift
//  libIso18013
//
//  Created by Antonio on 11/10/24.
//


public class LibIso18013DAOMemory : LibIso18013DAOProtocol {
    
    public init() {
        self._documents = []
    }
    
    //TODO: should check thread safety with a lock
    var _documents : [DeviceDocument] = []
    
    public func getAllDocuments(state: DeviceDocumentState?) -> [DeviceDocumentProtocol] {
        guard let state = state else {
            return _documents
        }
        return _documents.filter({$0.state == state})
    }
    
    public func getAllMdlDocuments(state: DeviceDocumentState?) -> [DeviceDocumentProtocol] {
        return getAllDocuments(state: state).filter({
            $0.docType == DocType.mDL.rawValue
        })
    }
    
    public func getAllEuPidDocuments(state: DeviceDocumentState?) -> [DeviceDocumentProtocol] {
        return getAllDocuments(state: state).filter({
            $0.docType == DocType.euPid.rawValue
        })
    }
    
    public func getDocumentByIdentifier(identifier: String) throws -> DeviceDocumentProtocol {
        guard let document = _documents.first(where: {$0.identifier == identifier}) else {
            throw ErrorHandler.documentWithIdentifierNotFound
        }
        
        return document
    }
    
    public func deleteDocument(identifier: String) throws -> Bool {
        guard let documentIndex = _documents.firstIndex(where: {$0.identifier == identifier}) else {
            throw ErrorHandler.documentWithIdentifierNotFound
        }
        
        _documents.remove(at: documentIndex)
        
        return true
    }
    
    public func createDocument(docType: String, documentName: String, curve: ECCurveName = .p256, forceSecureEnclave: Bool = true) throws -> DeviceDocumentProtocol {
        
        let deviceKey = try LibIso18013Utils.shared.createSecurePrivateKey(curve: curve, forceSecureEnclave: forceSecureEnclave)
        
        return try createDocument(docType: docType, documentName: documentName, deviceKey: deviceKey)
    }
    
    public func createDocument(docType: String, documentName: String, deviceKey: CoseKeyPrivate) throws -> DeviceDocumentProtocol {
        let document = DeviceDocument(
            state:.unsigned,
            createdAt: Date(),
            deviceKey: deviceKey,
            docType: docType,
            name: documentName,
            identifier: UUID().uuidString,
            document: nil)
        
        _documents.append(document)
        
        return document
    }
    
    public func storeDocument(identifier: String, documentData: Data) throws -> String {
        guard let documentIndex = _documents.firstIndex(where: {$0.identifier == identifier}) else {
            throw ErrorHandler.documentWithIdentifierNotFound
        }
        
        let storedDocument = _documents[documentIndex]
        
        if storedDocument.state != .unsigned {
            throw ErrorHandler.documentMustBeUnsigned
        }
        
        guard let issuerSigned = IssuerSigned(data: documentData.bytes) else {
            throw ErrorHandler.documentDecodingFailedError
        }
         
        let document = Document(docType: storedDocument.docType, issuerSigned: issuerSigned)
        
        guard LibIso18013Utils.shared.isDevicePrivateKeyOfDocument(
            document: document,
            privateKey: storedDocument.deviceKey) else {
            throw ErrorHandler.invalidDeviceKeyError
        }
        
        _documents[documentIndex] = storedDocument.issued(document: document)
        
        return identifier
    }
    
}
