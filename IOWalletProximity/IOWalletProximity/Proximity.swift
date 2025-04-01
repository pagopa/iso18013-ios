//
//  Proximity.swift
//  IOWalletProximity
//
//  Created by Antonio on 13/11/24.
//
internal import SwiftCBOR
import Foundation

public enum ProximityEvents {
    case onBleStart
    case onBleStop
    case onDocumentRequestReceived(request:  (request: [(docType: String, nameSpaces: [String: [String: Bool]])]?, isAuthenticated: Bool)?)
    case onDocumentPresentationCompleted
    case onError(error: Error)
    case onLoading
}

public class Proximity: @unchecked Sendable {
    
    public static let shared: Proximity = Proximity()
    
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
    //      - deviceResponse: deviceResponse as cbor encoded
    public func dataPresentation(allowed: Bool, _ deviceResponse: [UInt8]) {
        guard let proximityListener = self.proximityListener else {
            return
        }
        
        guard let deviceResponse = DeviceResponse(data: deviceResponse) else {
            return
        }
        
        
        proximityListener.onResponse?(allowed, deviceResponse)
        
    }
    
    
    
   /**
    * Generate session transcript with OID4VPHandover
    * This method is used for ISO 18013-7 OID4VP flow.
    *
    * - Parameters:
    *   - clientId: Authorization Request 'client_id'
    *   - responseUri: Authorization Request 'response_uri'
    *   - authorizationRequestNonce: Authorization Request 'nonce'
    *   - mdocGeneratedNonce: cryptographically random number with sufficient entropy
    *
    * - Returns: A CBOR-encoded SessionTranscript object
    */
    public func generateOID4VPSessionTranscriptCBOR(
        clientId: String,
        responseUri: String,
        authorizationRequestNonce: String,
        mdocGeneratedNonce: String
    ) -> [UInt8] {
        return generateOID4VPSessionTranscript(
            clientId: clientId,
            responseUri: responseUri,
            authorizationRequestNonce: authorizationRequestNonce,
            mdocGeneratedNonce: mdocGeneratedNonce
        ).encode(options: CBOROptions())
    }
    
    
    private func generateOID4VPSessionTranscript(
        clientId: String,
        responseUri: String,
        authorizationRequestNonce: String,
        mdocGeneratedNonce: String
    ) -> SessionTranscript {
        return SessionTranscript(
            handOver: OID4VPHandover(
                clientId: clientId,
                responseUri: responseUri,
                authorizationRequestNonce: authorizationRequestNonce,
                mdocGeneratedNonce: mdocGeneratedNonce
            ).toCBOR(options: CBOROptions())
        )
    }
    
    /**
     * Generate DeviceResponse to request for data from the reader.
     *
     * - Parameters:
     *   - allowed: User has allowed the verification process
     *   - items: json of map of [documentType: [nameSpace: [elementIdentifier: allowed]]] as String
     *   - documents: List of documents.
     *   - sessionTranscript: optional CBOR encoded session transcript
     *
     * - Returns: A CBOR-encoded DeviceResponse object
     */
    public func generateDeviceResponseFromJson(allowed: Bool,
                                                         items: String?,
                                               documents: [ProximityDocument]?,
                                                         sessionTranscript: [UInt8]?) -> [UInt8]? {
        var decodedItems: [String: [String: [String: Bool]]]? = nil
        if let items = items {
            if let itemsData = items.data(using: .utf8) {
                if let itemsJson = try? JSONDecoder().decode([String: [String: [String: Bool]]].self, from: itemsData) {
                    decodedItems = itemsJson
                }
            }
        }
        
        return generateDeviceResponse(allowed: allowed, items: decodedItems, documents: documents, sessionTranscript: sessionTranscript)
    }
    
    /**
     * Generate DeviceResponse to request for data from the reader.
     *
     * - Parameters:
     *   - allowed: User has allowed the verification process
     *   - items: json of map of [documentType: [nameSpace: [elementIdentifier: allowed]]]
     *   - documents: List of documents.
     *   - sessionTranscript: optional CBOR encoded session transcript
     *
     * - Returns: A CBOR-encoded DeviceResponse object
     */
    public func generateDeviceResponse(allowed: Bool,
                                       items: [String: [String: [String: Bool]]]?,
                                               documents: [ProximityDocument]?,
                                               sessionTranscript: [UInt8]?) -> [UInt8]? {
       
        
        var documentsWithKeys: [String: ([UInt8], CoseKeyPrivate)] = [:]
        
        documents?.forEach({
            item in
            
            documentsWithKeys[item.docType] =  (item.issuerSigned, item.deviceKey)
        })
        
        
        return generateDeviceResponseCBOR(allowed: allowed, items: items, documents: documentsWithKeys, sessionTranscript: sessionTranscript)
    }
    
    
    private func generateDeviceResponseCBOR(
        allowed: Bool,
        items: [String: [String: [String: Bool]]]?,
        documents: [String: ([UInt8], CoseKeyPrivate)]?,
        sessionTranscript: [UInt8]? = nil
    ) -> [UInt8]? {
        
        let transcript: SessionTranscript?
        
        if let sessionTranscript = sessionTranscript {
            transcript = SessionTranscript.init(data: sessionTranscript)
        }
        else {
            transcript = nil
        }
        
        return generateDeviceResponse(allowed: allowed, items: items, documents: documents, sessionTranscript: transcript).encode()
    }
    
    private func generateDeviceResponse(allowed: Bool,
                                         items: [String: [String: [String: Bool]]]?,
                                         documents: [String: ([UInt8], CoseKeyPrivate)]?,
                                         sessionTranscript: SessionTranscript?) -> DeviceResponse? {
        
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
            
            guard let issuerSignedWithKey = documents[documentType] else {
                return
            }
            
            let deviceKey = issuerSignedWithKey.1
            let issuerSignedData = issuerSignedWithKey.0
            
            guard let issuerSigned = IssuerSigned(data: issuerSignedData) else {
                return
            }
            
            guard let request = items[documentType] else {
                return
            }
            
            if let responseDocument = buildResponseDocument(request: request, issuerSigned: issuerSigned, deviceKey: deviceKey, sessionTranscript:  sessionTranscript ?? sessionEncryption.transcript) {
                
                requestedDocuments.append(responseDocument)
            }
            else {
                if let docType = issuerSigned.issuerAuth?.mobileSecurityObject.docType {
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
    
    func getRequestedValues(request: [String: [String: Bool]], issuerSigned: IssuerSigned) -> (nsItemsToAdd: [String: [IssuerSignedItem]], errors: Errors?) {
        var nsItemsToAdd = [String: [IssuerSignedItem]]()
        var nsErrorsToAdd = [String: ErrorItems]()
        var errors: Errors?
        
        //indaghiamo intenttoretain
        
        if let issuerNs = issuerSigned.issuerNameSpaces {
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
    
    
    /**
     * Builds a response document using a SessionTranscript for authentication.
     * This method is used specifically for OID4VP flows.
     *
     * - Parameters:
     *   - request: Dictionary mapping namespaces to element identifiers which want to share
     *   - issuerSigned: The issuer-signed data for the document
     *   - deviceKey: The private key used for signing the device authentication
     *   - sessionTranscript: The session transcript containing the handover data
     *
     * - Returns: A Document object if document creation succeeded, nil otherwise
     */
    
    func buildResponseDocument(
        request: [String: [String: Bool]],
        issuerSigned: IssuerSigned,
        deviceKey: CoseKeyPrivate,
        sessionTranscript: SessionTranscript) -> Document? {
            
            
            let (nsItemsToAdd, errors) = getRequestedValues(request: request, issuerSigned: issuerSigned)
            
            if nsItemsToAdd.count > 0 {
                let issuerAuthToAdd = issuerSigned.issuerAuth
                let issToAdd = IssuerSigned(issuerNameSpaces: IssuerNameSpaces(nameSpaces: nsItemsToAdd),
                                            issuerAuth: issuerAuthToAdd)
                var devSignedToAdd: DeviceSigned? = nil
                
                guard let devAuth = try? MdocAuthentication.getDeviceAuthForTransferSignature(transcript: sessionTranscript, docType: issuerSigned.issuerAuth!.mobileSecurityObject.docType, privateKey: deviceKey) else {
                    return nil
                }
                
                devSignedToAdd = DeviceSigned(deviceAuth: devAuth)
                
                let docToAdd = Document(docType: issuerSigned.issuerAuth!.mobileSecurityObject.docType,
                                        issuerSigned: issToAdd,
                                        deviceSigned: devSignedToAdd,
                                        errors: errors)
                
                return docToAdd
            } else {
                return nil
            }
        }
    
    
    /**
     * Builds a response document using a SessionEncryption for authentication.
     * This method is used for traditional ISO 18013-5 flows.
     *
     * - Parameters:
     *   - request: Dictionary mapping namespaces to element identifiers which want to share
     *   - issuerSigned: The issuer-signed data for the document
     *   - deviceKey: The private key used for signing the device authentication
     *   - sessionEncryption: The session encryption containing keys and transcript data
     *
     * - Returns: A Document object if document creation succeeded, nil otherwise
     */
    
    func buildResponseDocument(
        request: [String: [String: Bool]],
        issuerSigned: IssuerSigned,
        deviceKey: CoseKeyPrivate,
        sessionEncryption: SessionEncryption) -> Document? {
            
            let dauthMethod: DeviceAuthMethod = .deviceSignature
            
            let (nsItemsToAdd, errors) = getRequestedValues(request: request, issuerSigned: issuerSigned)
            
            let eReaderKey = sessionEncryption.sessionKeys.publicKey
            
            if nsItemsToAdd.count > 0 {
                let issuerAuthToAdd = issuerSigned.issuerAuth
                let issToAdd = IssuerSigned(issuerNameSpaces: IssuerNameSpaces(nameSpaces: nsItemsToAdd),
                                            issuerAuth: issuerAuthToAdd)
                var devSignedToAdd: DeviceSigned? = nil
                let sessionTranscript = sessionEncryption.transcript
                
                let authKeys = CoseKeyExchange(publicKey: eReaderKey, privateKey: deviceKey)
                let mdocAuth = MdocAuthentication(transcript: sessionTranscript, authKeys: authKeys)
                guard let devAuth = try? mdocAuth.getDeviceAuthForTransfer(docType: issuerSigned.issuerAuth!.mobileSecurityObject.docType, dauthMethod: dauthMethod) else {
                    return nil
                }
                devSignedToAdd = DeviceSigned(deviceAuth: devAuth)
                
                let docToAdd = Document(docType: issuerSigned.issuerAuth!.mobileSecurityObject.docType,
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
