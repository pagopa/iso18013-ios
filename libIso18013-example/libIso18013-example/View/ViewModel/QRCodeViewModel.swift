//
//  QRCodeViewModel.swift
//  libIso18013-example
//
//  Created by Martina D'urso on 08/11/24.
//

import libIso18013

class QRCodeViewModel: QrEngagementListener, ObservableObject {
    
    enum BLEState {
        case success
        case loading
        case failure(String)
        case idle
    }
    
    @Published var state: BLEState = .idle
    
    var dao: LibIso18013DAOProtocol = LibIso18013DAOKeyChain()
    
    @Published var onRequest: ( onResponse: ((Bool, libIso18013.DeviceResponse?) -> Void)?,
                                deviceRequest: libIso18013.DeviceRequest,
                                sessionEncryption: SessionEncryption )?
    
    func didReceiveRequest(deviceRequest: libIso18013.DeviceRequest,
                           sessionEncryption: SessionEncryption,
                           onResponse: @escaping (Bool, libIso18013.DeviceResponse?) -> Void) {
        
        onRequest = (onResponse: onResponse, deviceRequest: deviceRequest, sessionEncryption: sessionEncryption)
        
    }
    
    func sendResponse(allowed: Bool, items: [String: [String: [String: Bool]]]?, onResponse: @escaping (Bool, libIso18013.DeviceResponse?) -> Void) {
        
        var requestedDocuments = [Document]()
        var docErrors = [[String: UInt64]]()
        
        onRequest?.deviceRequest.docRequests.forEach({
            request in
            if let sessionEncryption = onRequest?.sessionEncryption {
                
                if request.itemsRequest.docType == DocType.euPid.rawValue {
                    let documents = dao.getAllEuPidDocuments(state: .issued)
                    if let doc = documents.first {
                        if let responseDocument = buildResponseDocument(request: request,
                                                                        filterItems: items?[doc.identifier] ?? [:],
                                                                        document: doc,
                                                                        sessionEncryption: sessionEncryption) {
                            requestedDocuments.append(responseDocument)
                        }
                        else {
                            if let document = doc.document?.issuerSigned {
                                docErrors.append([document.issuerAuth!.mobileSecurityObject.docType: UInt64(0)])
                            }
                            
                        }
                    }
                } else if request.itemsRequest.docType == DocType.mDL.rawValue {
                    let documents = dao.getAllMdlDocuments(state: .issued)
                    if let doc = documents.first {
                        if let responseDocument = buildResponseDocument(request: request,
                                                                        filterItems: items?[doc.identifier] ?? [:],
                                                                        document: doc,
                                                                        sessionEncryption: sessionEncryption) {
                            requestedDocuments.append(responseDocument)
                        }
                        else {
                            if let document = doc.document?.issuerSigned {
                                docErrors.append([document.issuerAuth!.mobileSecurityObject.docType: UInt64(0)])
                            }
                        }
                    }
                }
            }
        })
        
        let documentErrors: [DocumentError]? = docErrors.count == 0 ? nil : docErrors.map({ DocumentError.init(documentErrors:$0) })
        
        let documentsToAdd = requestedDocuments.count == 0 ? nil : requestedDocuments
        
        let deviceResponseToSend = DeviceResponse(version: DeviceResponse.defaultVersion,
                                                  documents: documentsToAdd,
                                                  documentErrors: documentErrors,
                                                  status: 0)
        
        onResponse(allowed, deviceResponseToSend)
        onRequest = nil
    }
    
    func filterAllowedItems(nsItemsToAdd: [String: [IssuerSignedItem]],
                            allowed: [String: [String: Bool]]) -> [String: [IssuerSignedItem]] {
        var filteredNsItems = [String: [IssuerSignedItem]]()
        
        nsItemsToAdd.forEach({
            keyPair in
            
            let allowedItems = allowed[keyPair.key] ?? [:]
            
            let values = keyPair.value.filter({
                item in
                allowedItems[item.elementIdentifier] ?? false
            })
            
            filteredNsItems[keyPair.key] = values
        })
        
        return filteredNsItems
    }
    
    func buildResponseDocument(request: DocRequest,
                               filterItems: [String: [String: Bool]],
                               document: DeviceDocumentProtocol,
                               sessionEncryption: SessionEncryption) -> Document? {
        
        guard let doc = document.document else {
            return nil
        }
        
        let dauthMethod: DeviceAuthMethod = .deviceSignature
        
        let (allnsItems, errors, validReqItemsNsDict) = getRequestedItems(request: request,
                                                                            document: document)
        
        let nsItemsToAdd = filterAllowedItems(nsItemsToAdd: allnsItems,
                                                allowed: filterItems)
        
        let eReaderKey = sessionEncryption.sessionKeys.publicKey
        
        if nsItemsToAdd.count > 0 {
            let issuerAuthToAdd = doc.issuerSigned.issuerAuth
            let issToAdd = IssuerSigned(issuerNameSpaces: IssuerNameSpaces(nameSpaces: nsItemsToAdd),
                                        issuerAuth: issuerAuthToAdd)
            var devSignedToAdd: DeviceSigned? = nil
            let sessionTranscript = sessionEncryption.transcript
            
            let authKeys = CoseKeyExchange(publicKey: eReaderKey, privateKey: document.deviceKey)
            let mdocAuth = MdocAuthentication(transcript: sessionTranscript, authKeys: authKeys)
            guard let devAuth = try? mdocAuth.getDeviceAuthForTransfer(docType: doc.issuerSigned.issuerAuth!.mobileSecurityObject.docType, dauthMethod: dauthMethod) else {
                return nil
            }
            devSignedToAdd = DeviceSigned(deviceAuth: devAuth)
            
            let docToAdd = Document(docType: doc.issuerSigned.issuerAuth!.mobileSecurityObject.docType,
                                    issuerSigned: issToAdd,
                                    deviceSigned: devSignedToAdd,
                                    errors: errors)
            
            return docToAdd
            //docFiltered.append(docToAdd)
            //validReqItemsDocDict[doc.issuerAuth!.mobileSecurityObject.docType] = validReqItemsNsDict
        } else {
            //docErrors.append([doc.issuerAuth!.mobileSecurityObject.docType: UInt64(0)])
            return nil
        }
        //errorReqItemsDocDict[doc.issuerAuth!.mobileSecurityObject.docType] = nsErrorsToAdd.mapValues { Array($0.keys) }
        
    }
    
    func getRequestedItems(request: DocRequest, document: DeviceDocumentProtocol) -> (
        nsItemsToAdd: [String: [IssuerSignedItem]],
        errors: Errors?,
        validReqItemsNsDict: [String: [String]]) {
            
            var nsItemsToAdd = [String: [IssuerSignedItem]]()
            var nsErrorsToAdd = [String: ErrorItems]()
            var validReqItemsNsDict = [String: [String]]()
            var errors: Errors?
            
            if let doc = document.document {
                if let issuerNs = doc.issuerSigned.issuerNameSpaces {
                    let reqNamespaces =  Array(request.itemsRequest.requestNameSpaces.nameSpaces.keys)
                    
                    for reqNamespace in reqNamespaces {
                        let reqElementIdentifiers =  request.itemsRequest.requestNameSpaces.nameSpaces[reqNamespace]!.elementIdentifiers
                        
                        guard let items = issuerNs[reqNamespace] else {
                            nsErrorsToAdd[reqNamespace] = Dictionary(grouping: reqElementIdentifiers,
                                                                     by: {$0}).mapValues { _ in 0 }
                            continue
                        }
                        var itemsReqSet = Set(reqElementIdentifiers)
                        
                        //MARK: CHECK THIS LATER
                        
                        //                if haveSelectedItems == false {
                        //                    itemsReqSet = itemsReqSet.subtracting(IsoMdlModel.self.moreThan2AgeOverElementIdentifiers(reqDocIdOrDocType, reqNamespace, SimpleAgeAttest(namespaces: issuerNs.nameSpaces), reqElementIdentifiers))
                        //                }
                        
                        let itemsSet = Set(items.map({$0.elementIdentifier}))
                        var itemsToAdd = items.filter({ itemsReqSet.contains($0.elementIdentifier) })
                        
                        if itemsToAdd.count > 0 {
                            nsItemsToAdd[reqNamespace] = itemsToAdd
                            validReqItemsNsDict[reqNamespace] = itemsToAdd.map({$0.elementIdentifier})
                        }
                        let errorItemsSet = itemsReqSet.subtracting(itemsSet)
                        if errorItemsSet.count > 0 {
                            nsErrorsToAdd[reqNamespace] = Dictionary(grouping: errorItemsSet,
                                                                     by: { $0 }).mapValues { _ in 0 }
                        }
                    }
                }
                
                errors = nsErrorsToAdd.count == 0 ? nil : Errors(errors: nsErrorsToAdd)
                
            }
            return (nsItemsToAdd: nsItemsToAdd, errors: errors, validReqItemsNsDict: validReqItemsNsDict)
        }
    
    
    func didFinishedWithError(_ error: any Error) {
        state = BLEState.failure(error.localizedDescription)
    }
 
    func didChangeStatus(_ newStatus: libIso18013.TransferStatus) {
        switch newStatus {
            case .responseSent:
                state = BLEState.success
            case .initialized, .requestReceived, .disconnected, .connected, .qrEngagementReady:
                state = BLEState.idle
            case .initializing, .started, .userSelected:
                state = .loading
            case .error:
                return
        }
    }
    
    func buildDocumentAlert(nsItemsToAdd:  [String: [IssuerSignedItem]]) -> [String: [String]] {
        return Dictionary(uniqueKeysWithValues: nsItemsToAdd.map { (key, value) in
            (key, value.map { issuerSignedItem in
                issuerSignedItem.elementIdentifier
            })
        })
    }
    
    func buildAlert(item: DeviceRequest) -> [String: [String: [String]]]? {
        var requestedDocuments: [String: [String: [String]]] = [:]
        item.docRequests.forEach({
            request in
            if let sessionEncryption = onRequest?.sessionEncryption {
                
                if request.itemsRequest.docType == DocType.euPid.rawValue {
                    let documents = dao.getAllEuPidDocuments(state: .issued)
                    if let doc = documents.first {
                        let (nsItemsToAdd, errors, _) = getRequestedItems(request: request,
                                                                                            document: doc)
                        requestedDocuments[doc.identifier] = buildDocumentAlert(nsItemsToAdd: nsItemsToAdd)
                    }
                } else if request.itemsRequest.docType == DocType.mDL.rawValue {
                    let documents = dao.getAllMdlDocuments(state: .issued)
                    if let doc = documents.first {
                        let (nsItemsToAdd, errors, _) = getRequestedItems(request: request,
                                                                                            document: doc)
                        
                        requestedDocuments[doc.identifier] = buildDocumentAlert(nsItemsToAdd: nsItemsToAdd)
                    }
                }
            }
        })
        
        return requestedDocuments

    }
    
}
