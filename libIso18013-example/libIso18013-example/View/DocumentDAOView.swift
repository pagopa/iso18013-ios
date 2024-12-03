//
//  DocumentDAOView.swift
//  libIso18013-example
//
//  Created by Antonio on 11/10/24.
//

import SwiftUI
import libIso18013
import SwiftCBOR
import cbor

struct DocumentDAOView : View {
    
    var dao: LibIso18013DAOProtocol = LibIso18013DAOKeyChain()
    
    @State var isDocumentsExpanded: Bool = true
    @State var documents : [DeviceDocumentProtocol] = []
    @State var showAlert: Bool = false
    @State var error: Error?
    @State var selectedList: String = "all"
    
    @State var openSignView: Bool = false
    @State var selectedDocument: DeviceDocumentProtocol? = nil
    
    
    func bodyStack() -> AnyView {
        return AnyView(VStack {
            CustomButton(title: "create mDL Document", action: {
                performDocumentOperation {
                    let _ = try dao.createDocument(docType: DocType.mDL.rawValue, documentName: "Patente")
                }
            })
            CustomButton(title: "create euPid Document", action: {
                performDocumentOperation {
                    let _ = try dao.createDocument(docType: DocType.euPid.rawValue, documentName: "Carta d'identità")
                }
            })
            CustomButton(title: "load sample document", action: {
                performDocumentOperation {
                    let deviceKeyData: [UInt8] = Array(Data(base64Encoded: "piABAQIhWCB10y5Y864dyByb/O7VYXIAYIgf7jN98/d6QPhFKtPS5CJYIBR3pPncV0GAnSJR8Zl0XodZfDTJcMnnF2S2DklbqMjTI1ggLH8XPkgRj3VmWAy5F2WlOJR+cGKVtJMzH+/CHv3BW/skQA==")!)
                    
                    let doc = try dao.createDocument(docType: DocType.euPid.rawValue, documentName: "Carta d'identità", deviceKeyData: deviceKeyData)
                    
                    let _ = try dao.storeDocument(identifier: doc.identifier, documentData: Data(base64Encoded: DocumentDAOView.issuerSignedDocument1)!)
                }
            })
            
            documentsView().padding(.top, 8)
        })
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                bodyStack()
            }
            .padding(.top)
            .navigationTitle("DAO Example")
            .navigationDestination(isPresented: $openSignView, destination: {
                if let document = selectedDocument {
                    return Cose1SignView(deviceKey: CoseKeyPrivate(data: document.deviceKeyData))
                }
                
                return Cose1SignView()
                
            })
        }.onAppear() {
            documents = dao.getAllDocuments(state: nil)
        }.alert(isPresented: $showAlert) {
            var message = error?.localizedDescription
            if let error = error as? ErrorHandler {
                message = error.localizedDescription
            }
            return Alert(
                title: Text("Error"),
                message: Text(message ?? "Unknown error"),
                dismissButton: .default(Text("OK"))
            )
        }
        
    }
    
    func documentsView() -> AnyView {
        return AnyView(
            DisclosureGroup(isExpanded: $isDocumentsExpanded, content: {
                ForEach(documents, id: \.identifier) {
                    item in
                    documentView(item)
                }
            }, label: {
                HStack {
                    Text("Documents")
                    Picker(selection: $selectedList, content: {
                        Text("All").tag("all")
                        Text("mDL").tag("mdl")
                        Text("euPid").tag("eupid")
                    }, label: {Text("Filter") }).pickerStyle(.segmented).onChange(of: selectedList, perform: {
                        _ in
                        
                        performDocumentOperation {
                            
                        }
                    })
                    
                }
                
            }).padding(.horizontal, 16)
        )
    }
    
    func documentView(_ document: DeviceDocumentProtocol) -> AnyView {
        return  AnyView(HStack {
                                Text("Id: \(document.identifier)\nState: \(document.state.rawValue)\ndocType: \(document.docType)\npublicKey: \(Data(document.deviceKeyData).base64EncodedString())").fontWeight(.light).font(Font.caption)
                                Spacer()
                                HStack {
                                    Button(action: {
                                        performDocumentOperation {
                                            let _ = try dao.deleteDocument(identifier: document.identifier)
                                        }
                                    }, label: {Image(systemName: "trash") })
                                    Button(action: {
                                        selectedDocument = document
                                        openSignView = true
                                    }, label: {Image(systemName: "signature") })
                                    if (document.state == .unsigned) {
                                        Button(action: {
                                            performDocumentOperation {
                                                let _ = try dao.storeDocument(identifier: document.identifier, documentData: Data(base64Encoded: DocumentDAOView.issuerSignedDocument1)!)
                                            }
                                        }, label: {Image(systemName: "square.and.arrow.down") })
                                    }
                                }
                            })
    }
    
//    func documentView(_ document: DeviceDocumentProtocol) -> AnyView {
//        
//        
//        var displayStrings: [NameValue] = [NameValue]()
//        var displayImages: [NameImage] = [NameImage]()
//        
//        if let document = document.document,
//           let nameSpaces = ManageNameSpaces.getSignedItems(document.issuerSigned, document.docType) {
//            
//            ManageNameSpaces.extractDisplayStrings(nameSpaces, &displayStrings, &displayImages)
//            
//        }
//        
//        return AnyView(
//            GroupBox(content: {
//                
//                
//                VStack {
//                    InfoBoxView(title: "createdAt", docType: .date, subtitle:
//                            .text("\(document.createdAt)"))
//                    
//                    ForEach(displayStrings, id: \.name) { nameValue in
//                        if nameValue.mdocDataType == .array,
//                           let children = nameValue.children {
//                            ForEach(children, id: \.name) { element in
//                                InfoBoxView(title: nameValue.name,
//                                            docType: nameValue.mdocDataType ?? .string,
//                                            subtitle: .dictionary(element))
//                            }
//                        } else {
//                            InfoBoxView(title: nameValue.name,
//                                        docType: nameValue.mdocDataType ?? .string,
//                                        subtitle: .text(nameValue.value))
//                        }
//                    }
//                    
//                    
//                }
//            }, label: {
//                HStack {
//                    Text("Id: \(document.identifier)\nState: \(document.state.rawValue)\ndocType: \(document.docType)\npublicKey: \(Data(document.deviceKeyData).base64EncodedString())").fontWeight(.light).font(Font.caption)
//                    Spacer()
//                    HStack {
//                        Button(action: {
//                            performDocumentOperation {
//                                let _ = try dao.deleteDocument(identifier: document.identifier)
//                            }
//                        }, label: {Image(systemName: "trash") })
//                        Button(action: {
//                            selectedDocument = document
//                            openSignView = true
//                        }, label: {Image(systemName: "signature") })
//                        if (document.state == .unsigned) {
//                            Button(action: {
//                                performDocumentOperation {
//                                    let _ = try dao.storeDocument(identifier: document.identifier, documentData: Data(base64Encoded: DocumentDAOView.issuerSignedDocument1)!)
//                                }
//                            }, label: {Image(systemName: "square.and.arrow.down") })
//                        }
//                    }
//                }
//                
//            })
//        )
//    }
    
    func performDocumentOperation(operation: () throws -> Void) {
        do {
            try operation()
        }
        catch {
            self.error = error
            
            
            self.showAlert = true
        }
        
        if selectedList == "mdl" {
            documents = dao.getAllMdlDocuments(state: nil)
        }
        else if selectedList == "eupid" {
            documents = dao.getAllEuPidDocuments(state: nil)
        }
        else {
            documents = dao.getAllDocuments(state: nil)
        }
    }
    
    static let devicePrivateKey = "pSABAQIhWCB10y5Y864dyByb/O7VYXIAYIgf7jN98/d6QPhFKtPS5CJYIBR3pPncV0GAnSJR8Zl0XodZfDTJcMnnF2S2DklbqMjTI1ggLH8XPkgRj3VmWAy5F2WlOJR+cGKVtJMzH+/CHv3BW/s="
    
    static let issuerSignedDocument1 = "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dGXYGFh1pGZyYW5kb21YINroh7l6sXW1YqB27jaCKyBVc9JGhBDX1DkZ95zNPpqDaGRpZ2VzdElEA2xlbGVtZW50VmFsdWVvVGVzdCBQSUQgaXNzdWVycWVsZW1lbnRJZGVudGlmaWVycWlzc3VpbmdfYXV0aG9yaXR52BhYZqRmcmFuZG9tWCBwoD7infX3dXRbxuuxZPnNaT4XAziDZYL5VjvhlFyp2GhkaWdlc3RJRARsZWxlbWVudFZhbHVlYkZDcWVsZW1lbnRJZGVudGlmaWVyb2lzc3VpbmdfY291bnRyedgYWG+kZnJhbmRvbVggKTZRmDb7uoKgUNeD95wUFpVIqCeGCbUdpOdIWbJRScxoZGlnZXN0SUQFbGVsZW1lbnRWYWx1ZdkD7GoyMDI0LTEwLTExcWVsZW1lbnRJZGVudGlmaWVybWlzc3VhbmNlX2RhdGXYGFhjpGZyYW5kb21YIJnsUbFRcOnZB/xEpiKECuvDiK4FZH/T72I+6i2IvB+1aGRpZ2VzdElEBmxlbGVtZW50VmFsdWVkSm9obnFlbGVtZW50SWRlbnRpZmllcmpnaXZlbl9uYW1l2BhYYKRmcmFuZG9tWCBX0CuDuXM9qlhHCSLIOUh5e7MhzAPz1Tz6/hCtoFqz82hkaWdlc3RJRAdsZWxlbWVudFZhbHVl9XFlbGVtZW50SWRlbnRpZmllcmthZ2Vfb3Zlcl8xOA=="
}

#Preview {
    DocumentDAOView()
}
