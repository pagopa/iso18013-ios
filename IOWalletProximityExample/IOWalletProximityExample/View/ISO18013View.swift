//
//  ISO18013View.swift
//  IOWalletProximityExample
//
//  Created by antoniocaparello on 26/02/26.
//

import SwiftUI
import IOWalletProximity

struct ISO118013View: View {
    
    @State var nfcEngagement: Bool =  true
    @State var qrCodeEngagement: Bool =  true
    @State var nfcEngagementLate: Bool =  true
    @State var nfcDataTransfer: Bool =  true
    @State var bleDataTransfer: Bool = true
    
    @State var qrCode: String? = nil
    @State var loading: Bool = false
    @State var nfc: Bool = false
    
    @State var isEngaging = false
    @State var dataTransferArgs: ISO18013DataTransferArgs?
    
    @State var isCompleted = false
    @State var error: String?
    
    @State var bleConnecting = false
    @State var bleConnected = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var timeRemaining = 0
    
    func _retrivalMethods() -> [ISO18013DataTransferMode] {
        var result: [ISO18013DataTransferMode] = []
        
        if (bleDataTransfer) {
            result.append(.ble)
        }
        
        if (nfcDataTransfer) {
            result.append(.nfc)
        }
        
        return result
    }
    
    func _engagementModes() -> [ISO18013EngagementMode] {
        var result: [ISO18013EngagementMode] = []
        
        if (nfcEngagement) {
            result.append(.nfc)
        }
        
        if (qrCodeEngagement) {
            result.append(.qrCode)
        }
        
        return result
    }
    
    func _bleConnectionStatusView() -> some View {
        return VStack {
            if bleConnecting {
                if bleConnected {
                    Text("BLE Connected")
                }
                else {
                    Text("BLE Connecting")
                }
            }
        }
    }
    
    func _nfcTimerView() -> some View {
        VStack {
            if (timeRemaining > 0) {
                
                Text("\(nfc ? "Session" : "Cooldown") remaining time:\n \(timeRemaining)")
                    .font(.largeTitle)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 5)
                    .background(.black.opacity(0.75))
                    .clipShape(.capsule)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    func _configView() -> some View {
        return VStack {
            Toggle(isOn: $qrCodeEngagement, label: {
                Text("QRCode Engagement")
            })
            Toggle(isOn: $nfcEngagement, label: {
                Text("NFC Engagement")
            })
            Toggle(isOn: $nfcEngagementLate, label: {
                Text("NFC Late Engagement")
            })
            Divider()
            Toggle(isOn: $bleDataTransfer, label: {
                Text("BLE Data Transfer")
            })
            Toggle(isOn: $nfcDataTransfer, label: {
                Text("NFC Data Transfer")
            })
            Divider()
            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 100))
                ], alignment: .center)  {
                    Button(action: {
                        qrCodeEngagement = true
                        nfcEngagement = false
                        nfcEngagementLate = false
                        nfcDataTransfer = false
                        bleDataTransfer = true
                    }, label: {
                        Text("QR Engagement + BLE Data Transfer")
                    })
                    .buttonStyle(.borderedProminent)
                    .tint(Color.blue)
                    Button(action: {
                        qrCodeEngagement = true
                        nfcEngagement = false
                        nfcEngagementLate = false
                        nfcDataTransfer = true
                        bleDataTransfer = false
                    }, label: {
                        Text("QR Engagement + NFC Data Transfer")
                    })
                    .buttonStyle(.borderedProminent)
                    .tint(Color.green)
                    Button(action: {
                        qrCodeEngagement = true
                        nfcEngagement = false
                        nfcEngagementLate = false
                        nfcDataTransfer = true
                        bleDataTransfer = true
                    }, label: {
                        Text("QR Engagement + (BLE & NFC Data Transfer)")
                    })
                    .buttonStyle(.borderedProminent)
                    .tint(Color.purple)
                    Button(action: {
                        qrCodeEngagement = false
                        nfcEngagement = true
                        nfcEngagementLate = false
                        nfcDataTransfer = false
                        bleDataTransfer = true
                    }, label: {
                        Text("NFC Engagement + BLE Data Transfer")
                    })
                    .buttonStyle(.borderedProminent)
                    .tint(Color.blue)
                    
                    Button(action: {
                        qrCodeEngagement = false
                        nfcEngagement = true
                        nfcEngagementLate = false
                        nfcDataTransfer = true
                        bleDataTransfer = false
                    }, label: {
                        Text("NFC Engagement + NFC Data Transfer")
                    })
                    .buttonStyle(.borderedProminent)
                    .tint(Color.green)
                    Button(action: {
                        qrCodeEngagement = false
                        nfcEngagement = true
                        nfcEngagementLate = false
                        nfcDataTransfer = true
                        bleDataTransfer = true
                    }, label: {
                        Text("NFC Engagement + (BLE & NFC Data Transfer)")
                    })
                    .buttonStyle(.borderedProminent)
                    .tint(Color.purple)
                    
                }
            Divider()
            Button(action: {
                
                let trustedCertificates: [[Data]] = [
                    [
                        //https://pre.ta.wallet.ipzs.it/pki/ta.cer
                        Data(base64Encoded: "MIIDQzCCAuigAwIBAgIGAZc6+XlDMAoGCCqGSM49BAMCMIGzMQswCQYDVQQGEwJJVDEOMAwGA1UECAwFTGF6aW8xDTALBgNVBAcMBFJvbWExMTAvBgNVBAoMKElzdGl0dXRvIFBvbGlncmFmaWNvIGUgWmVjY2EgZGVsbG8gU3RhdG8xCzAJBgNVBAsMAklUMR4wHAYDVQQDDBVwcmUudGEud2FsbGV0LmlwenMuaXQxJTAjBgkqhkiG9w0BCQEWFnByb3RvY29sbG9AcGVjLmlwenMuaXQwHhcNMjUwNjA0MTI0NTE3WhcNMzAwNjAzMTI0NTE3WjCBszELMAkGA1UEBhMCSVQxDjAMBgNVBAgMBUxhemlvMQ0wCwYDVQQHDARSb21hMTEwLwYDVQQKDChJc3RpdHV0byBQb2xpZ3JhZmljbyBlIFplY2NhIGRlbGxvIFN0YXRvMQswCQYDVQQLDAJJVDEeMBwGA1UEAwwVcHJlLnRhLndhbGxldC5pcHpzLml0MSUwIwYJKoZIhvcNAQkBFhZwcm90b2NvbGxvQHBlYy5pcHpzLml0MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEaE0xyhd3e9LDT7uwHOclL5H3389gwiCwFhI3KOvidn0glBIHYxqH+4Z9VTMYWG5L8cwC9AaJUCNGu2dp5ZiiTKOB5TCB4jAdBgNVHQ4EFgQU81CDcYxAqV3ptM8iKbJ06r9wxBkwHwYDVR0jBBgwFoAU81CDcYxAqV3ptM8iKbJ06r9wxBkwDwYDVR0TAQH/BAUwAwEB/zBEBggrBgEFBQcBAQQ4MDYwNAYIKwYBBQUHMAKGKGh0dHBzOi8vcHJlLnRhLndhbGxldC5pcHpzLml0L3BraS90YS5jZXIwDgYDVR0PAQH/BAQDAgEGMDkGA1UdHwQyMDAwLqAsoCqGKGh0dHBzOi8vcHJlLnRhLndhbGxldC5pcHpzLml0L3BraS90YS5jcmwwCgYIKoZIzj0EAwIDSQAwRgIhAOsQYzR+eGf4je63VGHqkpmkBbfyOre+mfIdHHowWWR/AiEA58xBNb5UW5uMB+tQur8fq24RD5MmRHLYS6bDgIYmluw=")!
                    ]
                ]
                
                isCompleted = false
                isEngaging = true
                
                ISO18013.shared.start(
                    trustedCertificates,
                    engagementModes: _engagementModes(),
                    retrivalMethods: _retrivalMethods(),
                    delegate: self,
                    isNfcLateEngagement: nfcEngagementLate)
                
                
            }, label: {
                Text("START").frame(height: 60)
            })
            .buttonStyle(.borderedProminent)
            .tint(Color.green)
            .disabled(_nfcCanNotPerformActions)
            if !nfcEngagementLate {
                _nfcTimerView()
            }
        }.padding(.horizontal, 16)
            .padding(.vertical, 16)
    }
    
    var _nfcCanNotPerformActions: Bool {
        return (nfcEngagement || nfcDataTransfer) ? timeRemaining > 0 : false
    }
    
    func _backToSettings() {
        qrCode = nil
        loading = false
        nfc = false
        dataTransferArgs = nil
        isCompleted = false
        error = nil
        isEngaging = false
        bleConnecting = false
        bleConnected = false
        ISO18013.shared.stop()
    }
    
    func _engagementView() -> some View {
        return VStack(spacing: 24) {
            _bleConnectionStatusView()
            if let qrCode = self.qrCode {
                QRCode
                    .getQrCodeImage(qrCode: qrCode, inputCorrectionLevel: .m)
                    .resizable()
                    .frame(width: 200, height: 200)
            }
            if nfcEngagementLate {
                Button(action: {
                    do {
                        try ISO18013.shared.lateNfcInitialization()
                    }
                    catch {
                        print(error)
                    }
                }, label: {
                    Text("NFC")
                        .frame(width: 100, height: 100)
                }) .buttonStyle(.borderedProminent)
                    .tint(Color.green)
                    .disabled(_nfcCanNotPerformActions)
            }
            
            if nfcEngagement || nfcDataTransfer {
                _nfcTimerView()
            }
            
            Button(action: {
                _backToSettings()
            }, label: {
                Text("BACK")
            })
            .buttonStyle(.borderedProminent)
            .tint(Color.red)
        }
    }
    
    func _completeView() -> some View {
        return VStack {
            if self.error != nil {
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
                Text(self.error ?? "-")
                    .font(.subheadline)
                    .foregroundStyle(.red)
                
            }
            else {
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
            }
            Button("BACK") {
                _backToSettings()
            }.buttonStyle(.borderedProminent)
                .tint(Color.red)
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if loading || nfc {
                    ProgressView()
                        .tint(Color.blue)
                        .scaleEffect(4)
                        .frame(width: 100, height: 100)
                }
                
                if !isEngaging {
                    _configView()
                }
                else {
                    if isCompleted {
                        _completeView()
                    }
                    else {
                        _engagementView()
                    }
                    
                }
            }
        }
        .onReceive(timer) {
            time in
            if timeRemaining > 0 {
                timeRemaining -= 1
            }
        }
        .sheet(isPresented: .init(get: {
            return dataTransferArgs != nil
        }, set: {
            _ in
        })) {
            let (isAuthenticated, request) = deviceRequestToMap(deviceRequest: dataTransferArgs!.request)
            DeviceRequestAlert(isAuthenticated: isAuthenticated, requested: request, response: {
                allowed, items in
                
                defer {
                    dataTransferArgs = nil
                }
                
                respondToDeviceRequest(allowed, items: items)
            })
        }
    }
    
    func respondToDeviceRequest(_ allowed: Bool, items: [String : [String : [String : Bool]]]?) {
        let documents = LibIso18013DAOKeyChain().getAllDocuments(state: .issued).compactMap({
            if let issuerSigned = $0.issuerSigned {
                return ProximityDocument(docType: $0.docType, issuerSigned: issuerSigned, deviceKeyRaw: $0.deviceKeyData)
            }
            return nil
        })
        
        do {
            if (allowed) {
                let deviceResponse = try ISO18013.shared.generateDeviceResponse(items: items, documents: documents, sessionTranscript: nil)
                
                try ISO18013.shared.dataPresentation( deviceResponse)
            }
            else {
                try ISO18013.shared.errorPresentation(.errorCborDecoding)
            }
            
        } catch {
            self.error = "\(error)"
            self.isCompleted = true
        }
    }
}

extension ISO118013View : ISO18013Delegate {
    func onEvent(event: ISO18013Event) {
        print(event)
        
        if #available(iOS 17.4, *) {
            ISO18013.shared.setNfcHceMessage(message: "\(event)")
        }
        
        switch(event) {
        case .bleConnecting:
            self.loading = true
            self.bleConnecting = true
        case .bleConnected:
            self.loading = false
            self.bleConnected = true
        case .qrCode(let qrCode):
            self.error = nil
            self.isCompleted = false
            self.qrCode = qrCode
            break
        case .error(let error):
            self.loading = false
            self.error = "\(error)"
            self.isCompleted = true
            break
        case .dataTransferStarted(let args):
            self.loading = true
            if (args.engagementMethod == .nfc || args.retrivalMethod == .nfc && nfc) {
                completeDataTransferWithoutUserActions(deviceRequest: args.request)
            }
            else {
                self.dataTransferArgs = args
            }
            break
        case .nfcEngagementStarted:
            self.loading = true
            self.nfc = true
            break
        case .nfcStarted:
            self.nfc = true
            self.timeRemaining = Int(ISO18013.nfcHLESessionTimeRemaining)
            break
        case .nfcStopped:
            self.nfc = false
            self.timeRemaining = Int(ISO18013.nfcHLESessionCoolDownTimeRemaining)
            break
        case .dataTransferStopped:
            self.loading = false
            self.isCompleted = true
            break
        default:
            break
        }
    }
    
    private func completeDataTransferWithoutUserActions(deviceRequest: [
        (docType: String,
         nameSpaces: [String: [String: Bool]],
         isAuthenticated: Bool)]?) {
             
             
             let (_, request) = deviceRequestToMap(deviceRequest: deviceRequest)
             
             respondToDeviceRequest(true, items: acceptAllFields(deviceRequestMap: request))
             
         }
    
    private func deviceRequestToMap(deviceRequest: [
        (docType: String,
         nameSpaces: [String: [String: Bool]],
         isAuthenticated: Bool)
    ]?) -> (isAuthenticated: Bool, request: [String: [String: [String]]]) {
        var isAuthenticated: Bool = true
        
        var deviceRequestMap : [String: [String: [String]]] = [:]
        
        deviceRequest?.forEach({
            item in
            
            var subReq: [String: [String]] = [:]
            
            item.nameSpaces.keys.forEach({
                nameSpace in
                subReq[nameSpace] =
                item.nameSpaces[nameSpace]?.keys.map({$0})
            })
            
            deviceRequestMap[item.docType] = subReq
            
            isAuthenticated = isAuthenticated && item.isAuthenticated
        })
        
        return (isAuthenticated: isAuthenticated, request: deviceRequestMap)
    }
    
    private func acceptAllFields(deviceRequestMap: [String: [String: [String]]]?) -> [String: [String: [String: Bool]]]? {
        var acceptedDeviceRequestMap: [String: [String: [String: Bool]]]? = [String: [String: [String: Bool]]]()
        
        deviceRequestMap?.forEach({
            document in
            
            var nameSpace = [String:[String:Bool]]()
            
            document.value.forEach({
                documentNameSpace in
                
                var items = [String: Bool]()
                
                documentNameSpace.value.forEach({
                    item in
                    
                    items[item] = true
                })
                
                nameSpace[documentNameSpace.key] = items
                
            })
            
            acceptedDeviceRequestMap?[document.key] = nameSpace
        })
        
        return acceptedDeviceRequestMap
    }
    
    
}


