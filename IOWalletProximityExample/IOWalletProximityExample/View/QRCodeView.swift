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
    
    @State var proximityEvent: ProximityEvents? = nil {
        didSet {
            showQrCode = false
            switch(proximityEvent) {
                case .onDeviceConnected, .onDeviceConnecting:
                    loading = true
                default:
                    loading = false
            }
        }
    }
    
    @State var loading: Bool = false
    @State var showQrCode: Bool = false
    
    func logEvent() -> String {
        switch(proximityEvent) {
            case .onDocumentPresentationCompleted:
                return "onDocumentPresentationCompleted"
            case .onDeviceConnecting:
                return "onDeviceConnecting"
            case .onDeviceConnected:
                return "onDeviceConnected"
            case .onDocumentRequestReceived( _):
                return "onDocumentRequestReceived"
            case .onDeviceDisconnected:
                return "onDeviceDisconnected"
            case .onError( _):
                return "onError"
            default:
                return "null"
        }
    }
    
    func viewForEvent() -> AnyView {
        //PRINT LOG TO CHECK IF EVENTS ARE CORRECT
        print(logEvent())
        
        
        if (showQrCode) {
            return AnyView(QRCode
                .getQrCodeImage(qrCode: qrCode, inputCorrectionLevel: .m)
                .resizable()
                .frame(width: 200, height: 200))
        }
        
        
        switch(proximityEvent) {
            case .onError(let error):
                if let proximityError = error as? ErrorHandler,
                   proximityError == .userRejected {
                    return AnyView(VStack {
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
                            startScanning()
                        }
                    })
                } else {
                    return AnyView(VStack {
                        HStack {
                            Text("Error")
                                .font(.title)
                                .foregroundStyle(.green)
                            Image(systemName: "checkmark")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundStyle(.red)
                        }
                        .padding(.bottom)
                        Button("Get another Qr Code") {
                            startScanning()
                        }
                    })
                }
                break
            case .onDocumentRequestReceived(let request):
                let req:  [String: [String: [String]]] = {
                    var popupRequest : [String: [String: [String]]] = [:]
                    
                    request?.forEach({
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
                
                
                return AnyView(DeviceRequestAlert(requested: req) {
                    allowed, items in
                    
                    let documents = LibIso18013DAOKeyChain().getAllDocuments(state: .issued).compactMap({
                        if let issuerSigned = $0.issuerSigned {
                            return ProximityDocument(docType: $0.docType, issuerSigned: issuerSigned, deviceKeyRaw: $0.deviceKeyData)
                        }
                        return nil
                    })
                    
                    do {
                        let deviceResponse = try Proximity.shared.generateDeviceResponse(allowed: allowed, items: items, documents: documents, sessionTranscript: nil)
                        
                        try Proximity.shared.dataPresentation(allowed: allowed, deviceResponse)
                        
                    } catch {
                        print(error)
                    }
                    
                })
                break
            case .onDeviceConnected:
                return AnyView(VStack {
                    HStack {
                        Text("Connected")
                            .font(.title)
                            .foregroundStyle(.green)
                        Image(systemName: "checkmark")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundStyle(.green)
                    }
                    .padding(.bottom)
                })
            case .onDeviceConnecting:
                return AnyView(VStack {
                    HStack {
                        Text("Connecting")
                            .font(.title)
                            .foregroundStyle(.green)
                        Image(systemName: "checkmark")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundStyle(.green)
                    }
                    .padding(.bottom)
                })
            default:
                return AnyView(VStack {
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
                    }
                })
                break
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                
                ZStack {
                    VStack {
                        Spacer()
                        viewForEvent()
                        Spacer()
                        
                        if loading {
                            Color.black.opacity(0.4)
                                .edgesIgnoringSafeArea(.all)
                            ProgressView()
                                .tint(Color.blue)
                                .scaleEffect(4)
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
        
        try? Proximity.shared.start(trustedCertificates)
        
        if let qrCode = try? Proximity.shared.getQrCode() {
            self.qrCode = qrCode
            self.showQrCode = true
        }
        else {
            self.qrCode = ""
            self.showQrCode = false
        }
    }
    
}

struct QRCodeView_Previews: PreviewProvider {
    static var previews: some View {
        QRCodeView()
    }
}
