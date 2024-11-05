//
//  QRCodeView.swift
//  libIso18013-example
//
//  Created by Martina D'urso on 09/10/24.
//

import SwiftUI
import libIso18013

struct QRCodeView: View {
    
    private var viewModel: QRCodeViewModel = QRCodeViewModel()
    @State var qrCode: String = ""
    
    var body: some View {
        VStack {
            Spacer()
            QRCode
                .getQrCodeImage(qrCode: qrCode, inputCorrectionLevel: .m)
                .resizable()
                .frame(width: 200, height: 200)
            Spacer()
        }
        .onAppear() {
            LibIso18013Proximity.shared.setListener(viewModel)
            do {
                qrCode = try LibIso18013Proximity.shared.getQrCodePayload()
                
            } catch {
                qrCode = "Error: \(error)"
            }
        }
    }
}

class QRCodeViewModel: QrEngagementListener {
    var dao: LibIso18013DAOProtocol = LibIso18013DAOKeyChain()
    
    func didReceiveRequest(deviceRequest: libIso18013.DeviceRequest, sessionEncryption: SessionEncryption, onResponse: @escaping (Bool, libIso18013.DeviceResponse?) -> Void) {
        
        var requestedDocuments = [Document]();
        var docErrors = [[String: UInt64]]()
        
        deviceRequest.docRequests.forEach({
            request in
            if request.itemsRequest.docType == DocType.euPid.rawValue {
                let documents = dao.getAllEuPidDocuments(state: .issued)
                if let doc = documents.first {
                    if let responseDocument = buildResponseDocument(request: request, document: doc, sessionEncryption: sessionEncryption) {
                        requestedDocuments.append(responseDocument)
                    }
                    else {
                        if let document = doc.document?.issuerSigned {
                            docErrors.append([document.issuerAuth!.mobileSecurityObject.docType: UInt64(0)])
                        }
                        
                    }
                }
            }
            else if request.itemsRequest.docType == DocType.mDL.rawValue {
                let documents = dao.getAllMdlDocuments(state: .issued)
                if let doc = documents.first {
                    if let responseDocument = buildResponseDocument(request: request, document: doc, sessionEncryption: sessionEncryption) {
                        requestedDocuments.append(responseDocument)
                    }
                    else {
                        if let document = doc.document?.issuerSigned {
                            docErrors.append([document.issuerAuth!.mobileSecurityObject.docType: UInt64(0)])
                        }
                    }
                }
            }
        })
        
        let documentErrors: [DocumentError]? = docErrors.count == 0 ? nil : docErrors.map({ DocumentError.init(documentErrors:$0) })
        
        let documentsToAdd = requestedDocuments.count == 0 ? nil : requestedDocuments
        let deviceResponseToSend = DeviceResponse(version: DeviceResponse.defaultVersion, documents: documentsToAdd, documentErrors: documentErrors, status: 0)
        
        onResponse(true, deviceResponseToSend)
        
    }
    
    func didReceiveRequest6(deviceRequest: libIso18013.DeviceRequest, onResponse: @escaping (Bool, libIso18013.DeviceResponse?) -> Void) {
        
        print(deviceRequest.docRequests)
        
        var validReqItemsDocDict = RequestItems()
        var errorReqItemsDocDict = RequestItems()
        
        deviceRequest.docRequests.forEach({
            request in
            if request.itemsRequest.docType == DocType.euPid.rawValue {
                let documents = dao.getAllEuPidDocuments(state: .issued)
                if let doc = documents.first {
                    
                }
            }
            else if request.itemsRequest.docType == DocType.mDL.rawValue {
                let documents = dao.getAllMdlDocuments(state: .issued)
                if let doc = documents.first {
                    
                }
            }
        })
        
    }
    
    func buildResponseDocument(request: DocRequest, document: DeviceDocumentProtocol, sessionEncryption: SessionEncryption) -> Document? {
        
        guard let doc = document.document else {
            return nil
        }
        
        let dauthMethod: DeviceAuthMethod = .deviceSignature
        
        let (nsItemsToAdd, errors, validReqItemsNsDict) = getRequestedItems(request: request, document: document)
        
        let eReaderKey = sessionEncryption.sessionKeys.publicKey
        
        if nsItemsToAdd.count > 0 {
            let issuerAuthToAdd = doc.issuerSigned.issuerAuth
            let issToAdd = IssuerSigned(issuerNameSpaces: IssuerNameSpaces(nameSpaces: nsItemsToAdd), issuerAuth: issuerAuthToAdd)
            var devSignedToAdd: DeviceSigned? = nil
            let sessionTranscript = sessionEncryption.transcript
            
            let authKeys = CoseKeyExchange(publicKey: eReaderKey, privateKey: document.deviceKey)
            let mdocAuth = MdocAuthentication(transcript: sessionTranscript, authKeys: authKeys)
            guard let devAuth = try? mdocAuth.getDeviceAuthForTransfer(docType: doc.issuerSigned.issuerAuth!.mobileSecurityObject.docType, dauthMethod: dauthMethod) else {
                //logger.error("Cannot create device auth");
                return nil
            }
            devSignedToAdd = DeviceSigned(deviceAuth: devAuth)
            
            let docToAdd = Document(docType: doc.issuerSigned.issuerAuth!.mobileSecurityObject.docType, issuerSigned: issToAdd, deviceSigned: devSignedToAdd, errors: errors)
            
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
                        
                        if itemsToAdd.count > 0 {
                            nsItemsToAdd[reqNamespace] = itemsToAdd
                            validReqItemsNsDict[reqNamespace] = itemsToAdd.map({$0.elementIdentifier})
                        }
                        let errorItemsSet = itemsReqSet.subtracting(itemsSet)
                        if errorItemsSet.count > 0 {
                            nsErrorsToAdd[reqNamespace] = Dictionary(grouping: errorItemsSet, by: { $0 }).mapValues { _ in 0 }
                        }
                    }
                }
                
                errors = nsErrorsToAdd.count == 0 ? nil : Errors(errors: nsErrorsToAdd)
                
            }
            return (nsItemsToAdd: nsItemsToAdd, errors: errors, validReqItemsNsDict: validReqItemsNsDict)
        }
    
    
    func didFinishedWithError(_ error: any Error) {
        
    }
    
    func onConnecting() {
        
    }
    
}

struct QRCodeView_Previews: PreviewProvider {
    static var previews: some View {
        QRCodeView()
    }
}
