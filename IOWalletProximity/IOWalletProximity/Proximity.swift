//
//  Proximity.swift
//  libIso18013
//
//  Created by Antonio on 13/11/24.
//

public enum ProximityEvents {
    case onBleStart
    case onBleStop
    case onDocumentRequestReceived(request:  (request: [(docType: String, nameSpaces: [String: [String: Bool]])]?, isAuthenticated: Bool)?)
    case onDocumentPresentationCompleted
    case onError(error: Error)
    case onLoading
}

public class Proximity {
    
    public static var shared: Proximity = Proximity()
    
    public var proximityHandler: ((ProximityEvents) -> Void)?
    
    private var proximityListener: ProximityListener?
    private var trustedCertificates: [SecCertificate] = []
    
    
    //  Initialize the BLE manager, set the necessary listeners. Start the BLE and generate the QRCode string
    //  - Parameters:
    //      - trustedCertificates: list of trusted certificates to verify reader validity
    //  - Returns: A string containing the DeviceEngagement data necessary to start the verification process
    public func start(_ trustedCertificates: [Data]? = nil) -> String? {
        
        self.trustedCertificates = trustedCertificates?.compactMap {
            SecCertificateCreateWithData(nil, $0 as CFData)
        } ?? []
        
        let _proximity = ProximityListener(proximity: self)
        
        LibIso18013Proximity.shared.setListener(_proximity)
        
        self.proximityListener = _proximity
        
        let qrCode = try? LibIso18013Proximity.shared.getQrCodePayload()
        
        proximityHandler?(.onBleStart)
        
        return qrCode
        
    }
    
    //  Responds to a request for data from the reader.
    //  - Parameters:
    //      - allowed: User has allowed the verification process
    //      - items: Map of [documentType: [nameSpace: [elementIdentifier: allowed]]]
    //      - documents: Map of documents. Key is docType, first item is document as cbor and second item is CoseKeyPrivate encoded (can rapresent keytag or raw private key)
    public func dataPresentation(allowed: Bool,
                                 items: [String: [String: [String: Bool]]]?,
                                 documents: [String: ([UInt8], [UInt8])]?) {
        
        guard let proximityListener = self.proximityListener else {
            return
        }
        
        var documentsWithKeys: [String: ([UInt8], CoseKeyPrivate)] = [:]
        
        documents?.keys.forEach({
            key in
            guard let item = documents?[key] else {
                return
            }
            guard let privateKey = CoseKeyPrivate.init(data: item.1) else {
                return
            }
            documentsWithKeys[key] =  (item.0, privateKey)
        })
        
        proximityListener.onResponse?(allowed, buildDeviceResponse(allowed: allowed, items: items, documents: documentsWithKeys))
        
        
    }
    
    //  Responds to a request for data from the reader.
    //  - Parameters:
    //      - allowed: User has allowed the verification process
    //      - items: Map of [documentType: [nameSpace: [elementIdentifier: allowed]]]
    //      - documents: Map of documents. Key is docType, first item is document as cbor and second item is SecKey
    public func dataPresentation(allowed: Bool,
                                 items: [String: [String: [String: Bool]]]?,
                                 documents: [String: ([UInt8], SecKey)]?) {
        
        guard let proximityListener = self.proximityListener else {
            return
        }
        
        var documentsWithKeys: [String: ([UInt8], CoseKeyPrivate)] = [:]
        
        documents?.keys.forEach({
            key in
            guard let item = documents?[key] else {
                return
            }
            guard let privateKey = CoseKeyPrivate.init(crv: .p256, secKey: item.1) else {
                return
            }
            documentsWithKeys[key] =  (item.0, privateKey)
        })
        
        proximityListener.onResponse?(allowed, buildDeviceResponse(allowed: allowed, items: items, documents: documentsWithKeys))
        
        
    }
    
    //  Stops the BLE manager and closes connections.
    public func stop() {
        LibIso18013Proximity.shared.stop()
        
        proximityHandler?(.onBleStop)
    }
    
    
    //  Retrives state of BLE
    //  - Returns: A Bool indicating if BLE is enabled
    public func isBleEnabled() -> Bool {
        let wait = DispatchGroup()
        
        wait.enter()
        
        var success = false
        
        MdocHelpers.checkBleAccess {
            status in
            switch(status) {
                case .success:
                    success = true
                case .failure(_):
                    success = false
                    
            }
            wait.leave()
        }
        
        wait.wait()
        
        return success
    }
    
    
    
    
    func onRequest(request:   (request: [(docType: String, nameSpaces: [String: [String: Bool]])]?, isAuthenticated: Bool)?) {
        proximityHandler?(.onDocumentRequestReceived(request: request))
    }
    
    func buildDeviceResponse(allowed: Bool,
                             items: [String: [String: [String: Bool]]]?,
                             documents: [String: (documentData: [UInt8], documentKey: CoseKeyPrivate)]?) -> DeviceResponse? {
        
        var requestedDocuments = [Document]()
        var docErrors = [[String: UInt64]]()
        
        guard let sessionEncryption = proximityListener?.sessionEncryption else {
            return nil
        }
        
        guard let items = items else {
            return nil
        }
        
        guard let documents = documents else {
            return nil
        }

        items.keys.forEach({
            documentType in
            
            guard let deviceDocument = documents[documentType] else {
                return
            }
            
            guard let document = Document(data: deviceDocument.documentData) else {
                return
            }
            
            guard let request = items[documentType] else {
                return
            }
            
            if let responseDocument = buildResponseDocument(request: request, document: document, deviceKey: deviceDocument.documentKey, sessionEncryption: sessionEncryption) {
                
                requestedDocuments.append(responseDocument)
            }
            else {
                if let docType = document.issuerSigned.issuerAuth?.mobileSecurityObject.docType {
                    docErrors.append([docType: UInt64(0)])
                }
            }
        })
        
        
        let documentErrors: [DocumentError]? = docErrors.count == 0 ? nil : docErrors.map({ DocumentError.init(documentErrors:$0) })
        
        let documentsToAdd = requestedDocuments.count == 0 ? nil : requestedDocuments
        
        let deviceResponseToSend = DeviceResponse(version: DeviceResponse.defaultVersion,
                                                  documents: documentsToAdd,
                                                  documentErrors: documentErrors,
                                                  status: 0)
        
        return deviceResponseToSend
    }
    
    func onDeviceRequest(_ deviceRequest: DeviceRequest) {
        
        let withAuthentication : (request: [(docType: String, nameSpaces: [String: [String: Bool]])]?, isAuthenticated: Bool)
        
        let isAuthenticated: Bool
        
        if let sessionEncryption = proximityListener?.sessionEncryption {
            let iaca: [SecCertificate] = trustedCertificates
            
            isAuthenticated = MdocTransferHelpers.isDeviceRequestValid(deviceRequest: deviceRequest, iaca: iaca, sessionEncryption: sessionEncryption)
        } else {
            isAuthenticated = false
        }
        
        withAuthentication = (
            request: buildDeviceRequestJson(item: deviceRequest),
            isAuthenticated: isAuthenticated)
        
        onRequest(request: withAuthentication)
    }
    
    func buildDeviceRequestJson(item: DeviceRequest) -> [(docType: String, nameSpaces: [String: [String: Bool]])]? {
        
        var requestedDocuments: [(docType: String, nameSpaces: [String: [String: Bool]])] = []
        
        item.docRequests.forEach({
            request in
            
            requestedDocuments.append((docType: request.itemsRequest.docType, nameSpaces: getRequestedItems(request: request)))
        })
        
        return requestedDocuments
    }
    
    
    func getRequestedItems(request: DocRequest) -> [String: [String: Bool]] {
        var nsItemsToAdd = [String: [String: Bool]]()
        
        let reqNamespaces =  Array(request.itemsRequest.requestNameSpaces.nameSpaces.keys)
        
        for reqNamespace in reqNamespaces {
            nsItemsToAdd[reqNamespace] = request.itemsRequest.requestNameSpaces.nameSpaces[reqNamespace]?.dataElements
        }
        
        return nsItemsToAdd
    }
   
    func getRequestedValues(request: [String: [String: Bool]], doc: Document) -> (nsItemsToAdd: [String: [IssuerSignedItem]], errors: Errors?) {
        var nsItemsToAdd = [String: [IssuerSignedItem]]()
        var nsErrorsToAdd = [String: ErrorItems]()
        var errors: Errors?
        
        //indaghiamo intenttoretain
        
        if let issuerNs = doc.issuerSigned.issuerNameSpaces {
            request.keys.forEach({
                reqNamespace in
                
                guard let reqItems = request[reqNamespace] else {
                    return
                }
                
                var reqElementIdentifiers = reqItems.filter({
                    key, value in
                    
                    return value
                }).map({
                    key, value in
                    return key
                })
                
                
                guard let items = issuerNs[reqNamespace] else {
                    nsErrorsToAdd[reqNamespace] = Dictionary(grouping: reqElementIdentifiers,
                                                             by: {$0}).mapValues { _ in 0 }
                    return
                }
                
                var itemsReqSet = Set(reqElementIdentifiers)
                
                
                let itemsSet = Set(items.map({$0.elementIdentifier}))
                var itemsToAdd = items.filter({ itemsReqSet.contains($0.elementIdentifier) })
                
                if itemsToAdd.count > 0 {
                    nsItemsToAdd[reqNamespace] = itemsToAdd
                }
                
                let errorItemsSet = itemsReqSet.subtracting(itemsSet)
                if errorItemsSet.count > 0 {
                    nsErrorsToAdd[reqNamespace] = Dictionary(grouping: errorItemsSet,
                                                             by: { $0 }).mapValues { _ in 0 }
                }
                
            })
        }
        
        errors = nsErrorsToAdd.count == 0 ? nil : Errors(errors: nsErrorsToAdd)
        
        return (nsItemsToAdd: nsItemsToAdd, errors: errors)
    }
    
    
    func buildResponseDocument(
        request: [String: [String: Bool]],
        document: Document,
        deviceKey: CoseKeyPrivate,
        sessionEncryption: SessionEncryption) -> Document? {
            
            let dauthMethod: DeviceAuthMethod = .deviceSignature
            
            let (nsItemsToAdd, errors) = getRequestedValues(request: request, doc: document)
            
            let eReaderKey = sessionEncryption.sessionKeys.publicKey
            
            if nsItemsToAdd.count > 0 {
                let issuerAuthToAdd = document.issuerSigned.issuerAuth
                let issToAdd = IssuerSigned(issuerNameSpaces: IssuerNameSpaces(nameSpaces: nsItemsToAdd),
                                            issuerAuth: issuerAuthToAdd)
                var devSignedToAdd: DeviceSigned? = nil
                let sessionTranscript = sessionEncryption.transcript
                
                let authKeys = CoseKeyExchange(publicKey: eReaderKey, privateKey: deviceKey)
                let mdocAuth = MdocAuthentication(transcript: sessionTranscript, authKeys: authKeys)
                guard let devAuth = try? mdocAuth.getDeviceAuthForTransfer(docType: document.issuerSigned.issuerAuth!.mobileSecurityObject.docType, dauthMethod: dauthMethod) else {
                    return nil
                }
                devSignedToAdd = DeviceSigned(deviceAuth: devAuth)
                
                let docToAdd = Document(docType: document.issuerSigned.issuerAuth!.mobileSecurityObject.docType,
                                        issuerSigned: issToAdd,
                                        deviceSigned: devSignedToAdd,
                                        errors: errors)
                
                return docToAdd
            } else {
                return nil
            }
    }
    
    class ProximityListener : QrEngagementListener {
        
        var proximity: Proximity
        var onResponse: ((Bool, DeviceResponse?) -> Void)?
        var sessionEncryption: SessionEncryption?
        
        
        init(proximity: Proximity) {
            self.proximity = proximity
        }
        
        func didChangeStatus(_ newStatus: TransferStatus) {
            switch(newStatus) {
                case .responseSent:
                    self.proximity.proximityHandler?(.onDocumentPresentationCompleted)
                    break
                case .initializing, .userSelected:
                    self.proximity.proximityHandler?(.onLoading)
                    break
                default:
                    break
            }
        }
        
        func didReceiveRequest(deviceRequest: DeviceRequest, sessionEncryption: SessionEncryption, onResponse: @escaping (Bool, DeviceResponse?) -> Void) {
            self.sessionEncryption = sessionEncryption
            self.onResponse = onResponse
            
            
            proximity.onDeviceRequest(deviceRequest)
            
        }
        
        func didFinishedWithError(_ error: any Error) {
            proximity.proximityHandler?(.onError(error: error))
        }
    }
}
