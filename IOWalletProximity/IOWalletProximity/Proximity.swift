//
//  Proximity.swift
//  IOWalletProximity
//
//  Created by Antonio on 13/11/24.
//
internal import SwiftCBOR
import Foundation

public enum ProximityError : Error, CustomStringConvertible {
    case nullObject(objectName: String)
    case decodingFailed(objectName: String)
    case error(error: Error)
    
    public var description: String {
        switch(self) {
            case .nullObject(let objectName):
                return "'\(objectName)' should not be null"
            
            case .decodingFailed(let objectName):
                return "'\(objectName)' decoding failed"
                
            case .error(let error):
                return error.localizedDescription
        }
    }
}

public enum SessionDataStatus : UInt64 {
    
    /*
     **Table 20 — SessionData status codes**
     __________________________________________________________________________
     | Status code | Description               | Action required                 |
     --------------------------------------------------------------------------
     |     10      | Error: session encryption | The session shall be terminated.|
     |     11      | Error: CBOR decoding      | The session shall be terminated.|
     |     20      | Session termination       | The session shall be terminated.|
     --------------------------------------------------------------------------
     
     */
    
    case errorSessionEncryption = 10
    case errorCborDecoding = 11
    case sessionTermination = 20
    
}

public enum ProximityEvents {
    //The device is done sending documents
    case onDocumentPresentationCompleted
    
    //The device is connecting to the verifier app
    case onDeviceConnecting
    
    //The device has connected to the verifier app
    case onDeviceConnected
    
    //The device has received a new request from the verifier app
    case onDocumentRequestReceived(request: [
        (docType: String,
         nameSpaces: [String: [String: Bool]],
         isAuthenticated: Bool)
    ]?)
    
    //The device has received the termination flag from the verifier app
    case onDeviceDisconnected
    
    //An error occurred
    case onError(error: Error)
    
}

public class Proximity: @unchecked Sendable {
    
    public static let shared: Proximity = Proximity()
    
    public var proximityHandler: ((ProximityEvents) -> Void)?
    
    private var proximityListener: ProximityListener?
    private var trustedCertificates: [SecCertificate] = []
    
    
    //  Initialize the BLE manager, set the necessary listeners. Start the BLE
    //  - Parameters:
    //      - trustedCertificates: list of trusted certificates to verify reader validity
    public func start(_ trustedCertificates: [Data]? = nil) throws {
        
        self.trustedCertificates = trustedCertificates?.compactMap {
            SecCertificateCreateWithData(nil, $0 as CFData)
        } ?? []
        
        let _proximity = ProximityListener(proximity: self)
        
        LibIso18013Proximity.shared.setListener(_proximity)
        
        self.proximityListener = _proximity
    }
    
    //  Generate the QRCode string
    //  - Returns: A string containing the DeviceEngagement data necessary to start the verification process
    public func getQrCode() throws -> String {
        do {
            let qrCode = try LibIso18013Proximity.shared.getQrCodePayload()
            
            return qrCode
        }
        catch {
            throw ProximityError.error(error: error)
        }
    }
    
    
    
    //  Responds to a request for data from the reader with deviceResponse.
    //  - Parameters:
    //      - deviceResponse: deviceResponse as cbor encoded
    public func dataPresentation(_ deviceResponse: [UInt8]) throws {
        guard let proximityListener = self.proximityListener else {
            throw ProximityError.nullObject(objectName: "proximityListener")
        }
        
        guard let deviceResponse = DeviceResponse(data: deviceResponse) else {
            throw ProximityError.decodingFailed(objectName: "deviceResponse")
        }
        
        
        proximityListener.onResponse?(true, deviceResponse, SessionDataStatus.sessionTermination.rawValue)
    }
    
    //  Responds to a request for data from the reader with error.
    //  - Parameters:
    //      - error: SessionDataStatus
    public func errorPresentation(_ error: SessionDataStatus) throws {
        guard let proximityListener = self.proximityListener else {
            throw ProximityError.nullObject(objectName: "proximityListener")
        }
        
        proximityListener.onResponse?(false, nil, error.rawValue)
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
     *   - items: json of map of [documentType: [nameSpace: [elementIdentifier: allowed]]] as String
     *   - documents: List of documents.
     *   - sessionTranscript: optional CBOR encoded session transcript
     *
     * - Returns: A CBOR-encoded DeviceResponse object
     */
    public func generateDeviceResponseFromJson(items: String?,
                                               documents: [ProximityDocument]?,
                                                         sessionTranscript: [UInt8]?) throws -> [UInt8] {
        var decodedItems: [String: [String: [String: Bool]]]? = nil
        if let items = items {
            if let itemsData = items.data(using: .utf8) {
                if let itemsJson = try? JSONDecoder().decode([String: [String: [String: Bool]]].self, from: itemsData) {
                    decodedItems = itemsJson
                }
            }
        }
        
        return try generateDeviceResponse(items: decodedItems, documents: documents, sessionTranscript: sessionTranscript)
    }
    
    /**
     * Generate DeviceResponse to request for data from the reader.
     *
     * - Parameters:
     *   - items: json of map of [documentType: [nameSpace: [elementIdentifier: allowed]]]
     *   - documents: List of documents.
     *   - sessionTranscript: optional CBOR encoded session transcript
     *
     * - Returns: A CBOR-encoded DeviceResponse object
     */
    public func generateDeviceResponse(items: [String: [String: [String: Bool]]]?,
                                               documents: [ProximityDocument]?,
                                               sessionTranscript: [UInt8]?) throws -> [UInt8] {
       
        
        var documentsWithKeys: [String: ([UInt8], CoseKeyPrivate)] = [:]
        
        documents?.forEach({
            item in
            
            documentsWithKeys[item.docType] =  (item.issuerSigned, item.deviceKey)
        })
        
        
        return try generateDeviceResponseCBOR(items: items, documents: documentsWithKeys, sessionTranscript: sessionTranscript)
    }
    
    
    private func generateDeviceResponseCBOR(
        items: [String: [String: [String: Bool]]]?,
        documents: [String: ([UInt8], CoseKeyPrivate)]?,
        sessionTranscript: [UInt8]? = nil
    ) throws -> [UInt8] {
        
        let transcript: SessionTranscript?
        
        if let sessionTranscript = sessionTranscript {
            transcript = SessionTranscript.init(data: sessionTranscript)
        }
        else {
            transcript = nil
        }
        
        let deviceResponse = try generateDeviceResponse(items: items, documents: documents, sessionTranscript: transcript)
        
        return deviceResponse.encode(options: CBOROptions())
    }
    
    
    
    private func generateDeviceResponse(items: [String: [String: [String: Bool]]]?,
                                        documents: [String: ([UInt8], CoseKeyPrivate)]?,
                                        sessionTranscript: SessionTranscript?) throws -> DeviceResponse {
        
        var requestedDocuments = [Document]()
        var docErrors = [[String: UInt64]]()
        
        let _sessionTranscript: SessionTranscript
        
        if let sessionTranscript = sessionTranscript {
            _sessionTranscript = sessionTranscript
        }
        else {
            guard let sessionEncryption = proximityListener?.sessionEncryption else {
                throw ProximityError.nullObject(objectName: "sessionEncryption")
            }
            _sessionTranscript = sessionEncryption.transcript
        }
      
        
        guard let items = items else {
            throw ProximityError.nullObject(objectName: "items")
        }
        
        guard let documents = documents else {
            throw ProximityError.nullObject(objectName: "documents")
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
            
            if let responseDocument = buildResponseDocument(request: request, issuerSigned: issuerSigned, deviceKey: deviceKey, sessionTranscript:  _sessionTranscript) {
                
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
    
    
    
    
    func onRequest(request:  [(docType: String, nameSpaces: [String: [String: Bool]], isAuthenticated: Bool)]) {
        proximityHandler?(.onDocumentRequestReceived(request: request))
    }
    
    func onDeviceRequest(_ deviceRequest: DeviceRequest) {
        onRequest(request: buildDeviceRequestJson(item: deviceRequest))
    }
    
    func buildDeviceRequestJson(item: DeviceRequest) -> [(docType: String, nameSpaces: [String: [String: Bool]], isAuthenticated: Bool)] {
        
        var requestedDocuments: [(docType: String, nameSpaces: [String: [String: Bool]], isAuthenticated: Bool)] = []
        
        item.docRequests.forEach({
            request in
            
            let isAuthenticated: Bool
            
            if let sessionEncryption = proximityListener?.sessionEncryption {
                let iaca: [SecCertificate] = trustedCertificates
                
                isAuthenticated = MdocTransferHelpers.isDeviceRequestDocumentValid(docR: request, iaca: iaca, sessionEncryption: sessionEncryption)
            }
            else {
                isAuthenticated = false
            }
            
            requestedDocuments.append((docType: request.itemsRequest.docType, nameSpaces: getRequestedItems(request: request), isAuthenticated: isAuthenticated))
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
        var onResponse: ((Bool, DeviceResponse?, UInt64) -> Void)?
        var sessionEncryption: SessionEncryption?
        
        
        init(proximity: Proximity) {
            self.proximity = proximity
        }
        
        func didChangeStatus(_ newStatus: TransferStatus) {
            switch(newStatus) {
                case .responseSent:
                    self.proximity.proximityHandler?(.onDocumentPresentationCompleted)
                    break
                case .disconnected:
                    self.proximity.proximityHandler?(.onDeviceDisconnected)
                case .connected:
                    self.proximity.proximityHandler?(.onDeviceConnecting)
                case .started:
                    self.proximity.proximityHandler?(.onDeviceConnected)
                default:
                    break
            }
        }
        
        func didReceiveRequest(deviceRequest: DeviceRequest, sessionEncryption: SessionEncryption, onResponse: @escaping (Bool, DeviceResponse?, UInt64) -> Void) {
            self.sessionEncryption = sessionEncryption
            self.onResponse = onResponse
            
            
            proximity.onDeviceRequest(deviceRequest)
            
        }
        
        func didFinishedWithError(_ error: any Error) {
            proximity.proximityHandler?(.onError(error: error))
        }
    }
}
