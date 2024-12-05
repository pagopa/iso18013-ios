//
//  QRCodeView.swift
//  libIso18013-example
//
//  Created by Martina D'urso on 09/10/24.
//

import SwiftUI
import libIso18013
import SwiftCBOR

struct QRCodeView: View {
    
    @State var qrCode: String = ""
    
    @State var proximityEvent: ProximityEvents = .onBleStop
    
    var body: some View {
        ZStack {
            VStack {
                Spacer()
                if case .onDocumentPresentationCompleted = proximityEvent {
                    HStack {
                        Text("Success")
                            .font(.title)
                            .foregroundStyle(.green)
                        Image(systemName: "checkmark")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundStyle(.green)
                    }
                    .padding(.bottom)
                    Button("Get another Qr Code") {
                        startScanning()
                        //viewModel.state = .idle
                    }
                } else {
                    QRCode
                        .getQrCodeImage(qrCode: qrCode, inputCorrectionLevel: .m)
                        .resizable()
                        .frame(width: 200, height: 200)
                }
                Spacer()
            }
            if case .onLoading = proximityEvent {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                ProgressView()
                    .tint(Color.blue)
                    .scaleEffect(4)
            }
            
            if case .onDocumentRequestReceived(let request) = proximityEvent {
                
                let req:  [String: [String: [String]]] = {
                    var popupRequest : [String: [String: [String]]] = [:]
                    
                     request?.request?.forEach({
                        item in
                         
                         var subReq: [String: [String]] = [:]
                         
                         item.nameSpaces.keys.forEach({
                             nameSpace in
                             subReq[nameSpace] =
                                 item.nameSpaces[nameSpace]?.keys.map({$0})
                         })
                         
                         popupRequest[item.docType] = subReq
                    })
                    
                    return popupRequest
                    
                    
                }()
                
                
                
                DeviceRequestAlert(requested: req) {
                    allowed, items in
                    
                    let documents = LibIso18013DAOKeyChain().getAllDocuments(state: .issued).compactMap({
                        if let documentData = $0.documentData {
                            return ($0.docType, documentData, $0.deviceKeyData)
                        }
                        return nil
                    })
                    
                    var documentMap: [String: ([UInt8], [UInt8])] = [:]

                    documents.forEach({
                        doc in
                        documentMap[doc.0] = (doc.1, doc.2)
                    })
                    
                    Proximity.shared.dataPresentation(allowed: allowed, items: items, documents: documentMap)
                }
            }
            
            
            
        }
        .onAppear() {
            startScanning()
        }
        .alert(isPresented: Binding<Bool>(
            get: {
                if case .onError(let error) = proximityEvent {
                    if let proximityError = error as? ErrorHandler {
                        if proximityError == .userRejected {
                            return false
                        }
                    }
                    return true
                }
                else {
                    return false
                }
                
            },
            set: { _ in }
        )) {
            Alert(title: Text("Error"), message: Text(({
                if case .onError(let error) = proximityEvent {
                    if let proximityError = error as? ErrorHandler {
                        return proximityError.localizedDescription
                    }
                    return error.localizedDescription
                } else {
                    return "Si è verificato un errore."
                }
            })()), dismissButton: .default(Text("OK")))
        }
    }
    
    func startScanning() {
        
        Proximity.shared.proximityHandler = {
            event in
            self.proximityEvent = event
        }
        
        let trustedCertificates: [Data] = []
        
        
        
        qrCode = Proximity.shared.start() ?? ""
    }
    
}

struct QRCodeView_Previews: PreviewProvider {
    static var previews: some View {
        QRCodeView()
    }
}
