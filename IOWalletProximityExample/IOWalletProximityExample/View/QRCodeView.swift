//
//  QRCodeView.swift
//  IOWalletProximityExample
//
//  Created by Martina D'urso on 09/10/24.
//

import SwiftUI
import IOWalletProximity

struct QRCodeView: View {
    
    @State var qrCode: String = ""
    
    @State var proximityEvent: ProximityEvents = .onBleStop
    
    var body: some View {
        NavigationStack {
            ScrollView {
               
        ZStack {
            VStack {
                Spacer()
                if case .onError(let error) = proximityEvent,
                let proximityError = error as? ErrorHandler,
                proximityError == .userRejected {
                    HStack {
                        Text("User Rejected")
                            .font(.title)
                            .foregroundStyle(.green)
                        Image(systemName: "checkmark")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundStyle(.green)
                    }
                    .padding(.bottom)
                    Button("Get another Qr Code") {
                        startScanning()                    }
                }
                else if case .onDocumentPresentationCompleted = proximityEvent {
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
            
            if case .onDocumentRequestReceived(let request, let json) = proximityEvent {
                
                let req:  [String: [String: [String]]] = {
                    var popupRequest : [String: [String: [String]]] = [:]
                    
                    (request["request"] as? [String: AnyHashable])?.forEach({
                        docType, nameSpaces in
                        var subReq: [String: [String]] = [:]
                        
                        (nameSpaces as? [String: AnyHashable])?.forEach({
                            nameSpace, items in
                            subReq[nameSpace] = (items as? [String: AnyHashable])?.keys.map({$0})
                        })
                        
                        popupRequest[docType] = subReq
                        
                    })
                    return popupRequest
                    
                    
                }()
                
                
                
                DeviceRequestAlert(requested: req) {
                    allowed, items in
                    
                    let documents = LibIso18013DAOKeyChain().getAllDocuments(state: .issued).compactMap({
                        if let issuerSigned = $0.issuerSigned {
                            return ProximityDocument(docType: $0.docType, issuerSigned: issuerSigned, deviceKeyRaw: $0.deviceKeyData)
                        }
                        return nil
                    })
                    
                    
                    guard let deviceResponse = Proximity.shared.generateDeviceResponse(allowed: allowed, items: items, documents: documents, sessionTranscript: nil) else {
                        return
                    }
                    
                    Proximity.shared.dataPresentation(allowed: allowed, deviceResponse)
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
            .padding(.top)
            .navigationTitle("QRCode")
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
