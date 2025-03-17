//
//  DocumentDAOView.swift
//  IOWalletProximityExample
//
//  Created by Antonio on 11/10/24.
//

import SwiftUI
import IOWalletProximity

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
            CustomButton(title: "load mDL Document", action: {
                performDocumentOperation {
                    let deviceKeyData: [UInt8] = Array(Data(base64Encoded: Documents.mdlPrivateKey)!)
                    
                    let doc = try dao.createDocument(docType: DocType.mDL.rawValue, documentName: "Patente", deviceKeyData: deviceKeyData)
                    
                    let _ = try dao.storeDocument(identifier: doc.identifier, documentData: Data(base64Encoded: Documents.mdlIssuerSigned)!)
                }
            })
            CustomButton(title: "load euPid Document", action: {
                performDocumentOperation {
                    let deviceKeyData: [UInt8] = Array(Data(base64Encoded: Documents.eupidPrivateKey)!)
                    
                    let doc = try dao.createDocument(docType: DocType.euPid.rawValue, documentName: "Carta Identità", deviceKeyData: deviceKeyData)
                    
                    let _ = try dao.storeDocument(identifier: doc.identifier, documentData: Data(base64Encoded: Documents.eupidIssuerSigned)!)
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
            .navigationTitle("Documents")
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
        return  AnyView(VStack {
            Divider()
            HStack {
                Text("Id: \(document.identifier)\nState: \(document.state.rawValue)\ndocType: \(document.docType)\npublicKey: \(Data(document.deviceKeyData).base64EncodedString())").fontWeight(.light).font(Font.caption)
                Spacer()
                HStack {
                    Button(action: {
                        performDocumentOperation {
                            let _ = try dao.deleteDocument(identifier: document.identifier)
                        }
                    }, label: {Image(systemName: "trash") })
                }
            }
        })
    }
    
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
}

#Preview {
    DocumentDAOView()
}
