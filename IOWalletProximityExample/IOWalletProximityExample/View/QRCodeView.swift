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
    
    //The intent assertion expires if any of the following occur:
    //The intent assertion object deinitializes -> occurs when Proximity.shared.stopNfc() is called
    
    //15 seconds elapse after the intent assertion initialized
    let nfcHLESessionTimeRemaining = 15
    
    //After the intent assertion expires, your app will need to wait 15 seconds before acquiring a new intent assertion.
    let nfcHLESessionCoolDownTimeRemaining = 15
    
    @State var nfcEvent: ProximityNfcEvents? = nil {
        didSet {
            switch(nfcEvent) {
            case .onStart:
                presentingNfc = true
                timeRemaining = nfcHLESessionTimeRemaining
            case .onStop:
                presentingNfc = false
                timeRemaining = nfcHLESessionCoolDownTimeRemaining
            default:
                break
            }
        }
    }
    
    @State var presentingNfc: Bool = false
    
    @State var loading: Bool = false
    @State var showQrCode: Bool = false
    
    @State var engagementMode: EngagementViewState = EngagementViewState.start
    
    @State private var timeRemaining = 0
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
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
            if engagementMode == .start {
                return AnyView(
                    VStack {
                        Button(action: {
                            if let qrCode = try? Proximity.shared.getQrCode() {
                                self.qrCode = qrCode
                                self.showQrCode = true
                            }
                            else {
                                self.qrCode = ""
                                self.showQrCode = false
                            }
                            engagementMode = .qrCode
                        }, label: {
                            Text("QRCode").frame(width: 200, height: 200)
                        }).frame(width: 200, height: 200)
                            .buttonStyle(.borderedProminent)
                                .tint(Color.blue)
                        Divider()
                            .padding(.top, 8)
                        Button(action: {
                            engagementMode = .nfc
                        }, label: {
                            Text("NFC").frame(width: 200, height: 200)
                        })
                            .buttonStyle(.borderedProminent)
                                .tint(Color.green)
                    })
            } else if engagementMode == .qrCode {
                return AnyView(
                    VStack {
                        QRCode
                            .getQrCodeImage(qrCode: qrCode, inputCorrectionLevel: .m)
                            .resizable()
                            .frame(width: 200, height: 200)
                        Button(action: {
                            engagementMode = .start
                        }, label: {
                            Text("BACK")
                        }).buttonStyle(.borderedProminent)
                            .tint(Color.red)
                    })
            } else if engagementMode == .nfc {
                
                if (presentingNfc) {
                    return AnyView(
                        VStack {
                            Text("Session remaining time:\n \(timeRemaining)")
                                .font(.largeTitle)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 5)
                                .background(.black.opacity(0.75))
                                .clipShape(.capsule)
                                .multilineTextAlignment(.center)
                            Button(action: {
                                Task {
                                    try? await Proximity.shared.stopNfc()
                                }
                                
                            }, label: {
                                Text("STOP NFC").frame(width: 100, height: 100)
                            })
                            .buttonStyle(.borderedProminent)
                            .tint(Color.purple)
                        }
                    )
                }
                else {
                    return AnyView(
                        VStack {
                            if (timeRemaining > 0) {
                                Text("HLE cooldown time:\n \(timeRemaining)")
                                    .font(.largeTitle)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 5)
                                    .background(.black.opacity(0.75))
                                    .clipShape(.capsule)
                                    .multilineTextAlignment(.center)
                            }
                            
                            Button(action: {
                                Task {
                                    try? await Proximity.shared.startNfc()
                                }
                                
                            }, label: {
                                Text("START NFC").frame(width: 200, height: 200)
                            })
                            .buttonStyle(.borderedProminent)
                            .tint(Color.green)
                            .disabled(timeRemaining > 0)
                            
                            Button(action: {
                                engagementMode = .start
                            }, label: {
                                Text("BACK")
                            }).buttonStyle(.borderedProminent)
                                .tint(Color.red)
                        })
                }
            }
            
            
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
                        Button("BACK") {
                            startScanning()
                        }
                    })
                } else {
                    return AnyView(VStack {
                        HStack {
                            Text("Error")
                                .font(.title)
                                .foregroundStyle(.red)
                            Image(systemName: "multiply")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundStyle(.red)
                        }
                        .padding(.bottom)
                        Button("BACK") {
                            startScanning()
                        }
                    })
                }
                break
            case .onDocumentRequestReceived(let request):
            var isAuthenticated: Bool = true
            
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
                        
                        isAuthenticated = isAuthenticated && item.isAuthenticated
                    })
                    
                    return popupRequest
                    
                    
                }()
                
                
            return AnyView(DeviceRequestAlert(isAuthenticated: isAuthenticated, requested: req) {
                    allowed, items in
                    
                    let documents = LibIso18013DAOKeyChain().getAllDocuments(state: .issued).compactMap({
                        if let issuerSigned = $0.issuerSigned {
                            return ProximityDocument(docType: $0.docType, issuerSigned: issuerSigned, deviceKeyRaw: $0.deviceKeyData)
                        }
                        return nil
                    })
                    
                    do {
                        if (allowed) {
                            let deviceResponse = try Proximity.shared.generateDeviceResponse(items: items, documents: documents, sessionTranscript: nil)
                            
                            try Proximity.shared.dataPresentation( deviceResponse)
                        }
                        else {
                            try Proximity.shared.errorPresentation(.errorCborDecoding)
                        }
                        
                        
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
                    Button("BACK") {
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
                        viewForEvent().onReceive(timer) {
                                time in
                                if timeRemaining > 0 {
                                    timeRemaining -= 1
                                    if (presentingNfc) {
                                        if (timeRemaining == 0) {
                                            Task {
                                                try? await Proximity.shared.stopNfc()
                                            }
                                        }
                                    }

                                }
                        }
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
                            if let proximityError = error as? ProximityError {
                                return proximityError.description
                            }
                            return error.localizedDescription
                        } else {
                            return "Si è verificato un errore."
                        }
                    })()), dismissButton: .default(Text("OK")))
                }
            }
            .padding(.top)
            .navigationTitle("Engagement")
        }
    }
    
    func startScanning() {
        
        Proximity.shared.proximityHandler = {
            event in
            self.proximityEvent = event
        }
        
        Proximity.shared.nfcHandler = {
            event in
            self.nfcEvent = event
        }
        
        let trustedCertificates: [[Data]] = [
            [
                //https://pre.ta.wallet.ipzs.it/pki/ta.cer
                Data(base64Encoded: "MIIDQzCCAuigAwIBAgIGAZc6+XlDMAoGCCqGSM49BAMCMIGzMQswCQYDVQQGEwJJVDEOMAwGA1UECAwFTGF6aW8xDTALBgNVBAcMBFJvbWExMTAvBgNVBAoMKElzdGl0dXRvIFBvbGlncmFmaWNvIGUgWmVjY2EgZGVsbG8gU3RhdG8xCzAJBgNVBAsMAklUMR4wHAYDVQQDDBVwcmUudGEud2FsbGV0LmlwenMuaXQxJTAjBgkqhkiG9w0BCQEWFnByb3RvY29sbG9AcGVjLmlwenMuaXQwHhcNMjUwNjA0MTI0NTE3WhcNMzAwNjAzMTI0NTE3WjCBszELMAkGA1UEBhMCSVQxDjAMBgNVBAgMBUxhemlvMQ0wCwYDVQQHDARSb21hMTEwLwYDVQQKDChJc3RpdHV0byBQb2xpZ3JhZmljbyBlIFplY2NhIGRlbGxvIFN0YXRvMQswCQYDVQQLDAJJVDEeMBwGA1UEAwwVcHJlLnRhLndhbGxldC5pcHpzLml0MSUwIwYJKoZIhvcNAQkBFhZwcm90b2NvbGxvQHBlYy5pcHpzLml0MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEaE0xyhd3e9LDT7uwHOclL5H3389gwiCwFhI3KOvidn0glBIHYxqH+4Z9VTMYWG5L8cwC9AaJUCNGu2dp5ZiiTKOB5TCB4jAdBgNVHQ4EFgQU81CDcYxAqV3ptM8iKbJ06r9wxBkwHwYDVR0jBBgwFoAU81CDcYxAqV3ptM8iKbJ06r9wxBkwDwYDVR0TAQH/BAUwAwEB/zBEBggrBgEFBQcBAQQ4MDYwNAYIKwYBBQUHMAKGKGh0dHBzOi8vcHJlLnRhLndhbGxldC5pcHpzLml0L3BraS90YS5jZXIwDgYDVR0PAQH/BAQDAgEGMDkGA1UdHwQyMDAwLqAsoCqGKGh0dHBzOi8vcHJlLnRhLndhbGxldC5pcHpzLml0L3BraS90YS5jcmwwCgYIKoZIzj0EAwIDSQAwRgIhAOsQYzR+eGf4je63VGHqkpmkBbfyOre+mfIdHHowWWR/AiEA58xBNb5UW5uMB+tQur8fq24RD5MmRHLYS6bDgIYmluw=")!
            ]
        ]
        
        try? Proximity.shared.start(trustedCertificates)
        
        engagementMode = .start
        
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

enum EngagementViewState {
    case start
    case qrCode
    case nfc
}
