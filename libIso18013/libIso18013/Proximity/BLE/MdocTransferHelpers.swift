//
//  MdocTransferHelpers.swift
//  libIso18013
//
//  Created by Antonio on 18/10/24.
//

import X509
import SwiftCBOR


class MdocTransferHelpers {
    /// Decrypt the contents of a data object and return a ``DeviceRequest`` object if the data represents a valid device request. If the data does not represent a valid device request, the function returns nil.
    /// - Parameters:
    ///   - deviceEngagement: deviceEngagement
    ///   - docs: IssuerSigned documents
    ///   - iaca: Root certificates trusted
    ///   - devicePrivateKeys: Device private keys
    ///   - dauthMethod: Method to perform mdoc authentication
    ///   - handOver: handOver structure
    /// - Returns: A ``DeviceRequest`` object
    
    public static func decodeRequest(deviceEngagement: DeviceEngagement?,  requestData: Data, dauthMethod: DeviceAuthMethod, readerKeyRawData: [UInt8]?, handOver: CBOR) -> Result<(sessionEncryption: SessionEncryption, deviceRequest: DeviceRequest), Error> {
        do {
            guard let seCbor = try CBOR.decode([UInt8](requestData)) else {
                //logger.error("Request Data is not Cbor");
                return .failure(ErrorHandler.requestDecodeError)
            }
            guard var se = SessionEstablishment(cbor: seCbor) else {
                //logger.error("Request Data cannot be decoded to session establisment");
                return .failure(ErrorHandler.requestDecodeError)
            }
            if se.eReaderKeyRawData == nil,
               let readerKeyRawData {
                se.eReaderKeyRawData = readerKeyRawData
            }
            
            guard se.eReaderKey != nil else {
                //logger.error("Reader key not available");
                return .failure(ErrorHandler.readerKeyMissing)
            }
            let requestCipherData = se.data
            guard let deviceEngagement else {
                //logger.error("Device Engagement not initialized");
                return .failure(ErrorHandler.deviceEngagementMissing)
            }
            // init session-encryption object from session establish message and device engagement, decrypt data
            let sessionEncryption = SessionEncryption(se: se, de: deviceEngagement, handOver: handOver)
            guard var sessionEncryption else {
                //logger.error("Session Encryption not initialized");
                return .failure(ErrorHandler.sessionEncryptionNotInitialized)
            }
            guard let requestData = try sessionEncryption.decrypt(requestCipherData) else { //logger.error("Request data cannot be decrypted");
                return .failure(ErrorHandler.requestDecodeError)
            }
            guard let deviceRequest = DeviceRequest(data: requestData) else {
                //logger.error("Decrypted data cannot be decoded");
                return .failure(ErrorHandler.requestDecodeError)
            }
            
            //var params: [String: Any] = [UserRequestKeys.valid_items_requested.rawValue: validRequestItems, UserRequestKeys.error_items_requested.rawValue: errorRequestItems]
           
            return .success((sessionEncryption: sessionEncryption, deviceRequest: deviceRequest))
        } catch { return .failure(error) }
    }
    
    public static func isDeviceRequestValid(deviceRequest: DeviceRequest, iaca: [SecCertificate], sessionEncryption: SessionEncryption) -> Bool {
        if let docR = deviceRequest.docRequests.first {
            let mdocAuth = MdocReaderAuthentication(transcript: sessionEncryption.transcript)
            if let readerAuthRawCBOR = docR.readerAuthRawCBOR,
               let certData = docR.readerCertificate,
               let x509 = try? X509.Certificate(derEncoded: [UInt8](certData)),
               let (isValidSignature, reasonFailure) = try? mdocAuth.validateReaderAuth(readerAuthCBOR: readerAuthRawCBOR, readerAuthCertificate: certData, itemsRequestRawData: docR.itemsRequestRawData!, rootCerts: iaca) {
                //params[UserRequestKeys.reader_certificate_issuer.rawValue] = MdocHelpers.getCN(from: x509.subject.description)
                //params[UserRequestKeys.reader_auth_validated.rawValue] = b
                if let reasonFailure {
                    //Certificate root authentication failed
                    //params[UserRequestKeys.reader_certificate_validation_message.rawValue] = reasonFailure
                    return false
                    
                }
                return isValidSignature
            }
        }
        return false
    }
    
    /// Construct ``DeviceResponse`` object to present from wallet data and input device request
    /// - Parameters:
    ///   - deviceRequest: Device request coming from verifier
    ///   - issuerSigned: Map of document ID to issuerSigned cbor data
    ///   - selectedItems: Selected items from user (Map of Document ID to namespaced items)
    ///   - sessionEncryption: Session Encryption data structure
    ///   - eReaderKey: eReader (verifier) ephemeral public key
    ///   - devicePrivateKeys: Device Private keys
    ///   - sessionTranscript: Session Transcript object
    ///   - dauthMethod: Mdoc Authentication method
    /// - Returns: (Device response object, valid requested items, error request items) tuple
    public static func getDeviceResponseToSend(deviceRequest: DeviceRequest?, issuerSigned: [String: IssuerSigned], selectedItems: RequestItems? = nil, sessionEncryption: SessionEncryption? = nil, eReaderKey: CoseKey? = nil, devicePrivateKeys: [String: CoseKeyPrivate], sessionTranscript: SessionTranscript? = nil, dauthMethod: DeviceAuthMethod) throws -> (response: DeviceResponse, validRequestItems: RequestItems, errorRequestItems: RequestItems)? {
        var docFiltered = [Document]();
        var docErrors = [[String: UInt64]]()
        
        
        var validReqItemsDocDict = RequestItems(); var errorReqItemsDocDict = RequestItems()
        guard deviceRequest != nil || selectedItems != nil else { fatalError("Invalid call") }
        let haveSelectedItems = selectedItems != nil
        // doc.id's (if have selected items), otherwise doc.types
        let reqDocIdsOrDocTypes = if haveSelectedItems { Array(selectedItems!.keys) } else { deviceRequest!.docRequests.map(\.itemsRequest.docType) }
        for reqDocIdOrDocType in reqDocIdsOrDocTypes {
            var docReq: DocRequest? // if selected items is null
            if haveSelectedItems == false {
                docReq = deviceRequest?.docRequests.findDoc(name: reqDocIdOrDocType)
                guard let (doc, _) = Array(issuerSigned.values).findDoc(name: reqDocIdOrDocType) else {
                    docErrors.append([reqDocIdOrDocType: UInt64(0)])
                    errorReqItemsDocDict[reqDocIdOrDocType] = [:]
                    continue
                }
            } else {
                guard issuerSigned[reqDocIdOrDocType] != nil else { continue }
            }
            let devicePrivateKey = devicePrivateKeys[reqDocIdOrDocType] ?? CoseKeyPrivate(crv: .p256) // used only if doc.id
            let doc = if haveSelectedItems { issuerSigned[reqDocIdOrDocType]! } else { Array(issuerSigned.values).findDoc(name: reqDocIdOrDocType)!.0 }
            // Document's data must be in CBOR bytes that has the IssuerSigned structure according to ISO 23220-4
            // Currently, the library does not support IssuerSigned structure without the nameSpaces field.
            guard let issuerNs = doc.issuerNameSpaces else {
                //logger.error("Document does not contain issuer namespaces");
                return nil
            }
            var nsItemsToAdd = [String: [IssuerSignedItem]]()
            var nsErrorsToAdd = [String: ErrorItems]()
            var validReqItemsNsDict = [String: [String]]()
            // for each request namespace
            let reqNamespaces = if haveSelectedItems { Array(selectedItems![reqDocIdOrDocType]!.keys)} else {  Array(docReq!.itemsRequest.requestNameSpaces.nameSpaces.keys) }
            for reqNamespace in reqNamespaces {
                let reqElementIdentifiers = if haveSelectedItems { Array(selectedItems![reqDocIdOrDocType]![reqNamespace]!)} else { docReq!.itemsRequest.requestNameSpaces.nameSpaces[reqNamespace]!.elementIdentifiers }
                guard let items = issuerNs[reqNamespace] else {
                    nsErrorsToAdd[reqNamespace] = Dictionary(grouping: reqElementIdentifiers, by: {$0}).mapValues { _ in 0 }
                    continue
                }
                var itemsReqSet = Set(reqElementIdentifiers)
                
                //MARK: CHECK THIS LATER
                
                //                if haveSelectedItems == false {
                //                    itemsReqSet = itemsReqSet.subtracting(IsoMdlModel.self.moreThan2AgeOverElementIdentifiers(reqDocIdOrDocType, reqNamespace, SimpleAgeAttest(namespaces: issuerNs.nameSpaces), reqElementIdentifiers))
                //                }
                
                let itemsSet = Set(items.map({$0.elementIdentifier}))
                var itemsToAdd = items.filter({ itemsReqSet.contains($0.elementIdentifier) })
                if let selectedItems {
                    let selectedNsItems = selectedItems[reqDocIdOrDocType]?[reqNamespace] ?? []
                    itemsToAdd = itemsToAdd.filter({ selectedNsItems.contains($0.elementIdentifier) })
                }
                if itemsToAdd.count > 0 {
                    nsItemsToAdd[reqNamespace] = itemsToAdd
                    validReqItemsNsDict[reqNamespace] = itemsToAdd.map({$0.elementIdentifier})
                }
                let errorItemsSet = itemsReqSet.subtracting(itemsSet)
                if errorItemsSet.count > 0 {
                    nsErrorsToAdd[reqNamespace] = Dictionary(grouping: errorItemsSet, by: { $0 }).mapValues { _ in 0 }
                }
            } // end ns for
            let errors: Errors? = nsErrorsToAdd.count == 0 ? nil : Errors(errors: nsErrorsToAdd)
            if nsItemsToAdd.count > 0 {
                let issuerAuthToAdd = doc.issuerAuth
                let issToAdd = IssuerSigned(issuerNameSpaces: IssuerNameSpaces(nameSpaces: nsItemsToAdd), issuerAuth: issuerAuthToAdd)
                var devSignedToAdd: DeviceSigned? = nil
                let sessionTranscript = sessionEncryption?.transcript ?? sessionTranscript
                if let eReaderKey, let sessionTranscript {
                    let authKeys = CoseKeyExchange(publicKey: eReaderKey, privateKey: devicePrivateKey)
                    let mdocAuth = MdocAuthentication(transcript: sessionTranscript, authKeys: authKeys)
                    guard let devAuth = try mdocAuth.getDeviceAuthForTransfer(docType: doc.issuerAuth!.mobileSecurityObject.docType, dauthMethod: dauthMethod) else {
                        //logger.error("Cannot create device auth");
                        return nil
                    }
                    devSignedToAdd = DeviceSigned(deviceAuth: devAuth)
                }
                let docToAdd = Document(docType: doc.issuerAuth!.mobileSecurityObject.docType, issuerSigned: issToAdd, deviceSigned: devSignedToAdd, errors: errors)
                docFiltered.append(docToAdd)
                validReqItemsDocDict[doc.issuerAuth!.mobileSecurityObject.docType] = validReqItemsNsDict
            } else {
                docErrors.append([doc.issuerAuth!.mobileSecurityObject.docType: UInt64(0)])
            }
            errorReqItemsDocDict[doc.issuerAuth!.mobileSecurityObject.docType] = nsErrorsToAdd.mapValues { Array($0.keys) }
        } // end doc for
        let documentErrors: [DocumentError]? = docErrors.count == 0 ? nil : docErrors.map({
            e in
            
            DocumentError.init(documentErrors:e)
        }
        )
        let documentsToAdd = docFiltered.count == 0 ? nil : docFiltered
        let deviceResponseToSend = DeviceResponse(version: DeviceResponse.defaultVersion, documents: documentsToAdd, documentErrors: documentErrors, status: 0)
        return (deviceResponseToSend, validReqItemsDocDict, errorReqItemsDocDict)
    }
    
}

