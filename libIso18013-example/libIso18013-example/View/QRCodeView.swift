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
                
                DeviceRequestAlert(requested: request) {
                    allowed, items in
                    
                    let documents = LibIso18013DAOKeyChain().getAllDocuments(state: .issued).map({
                        ($0.docType, $0.document.encode(), $0.deviceKey)
                    })
                    
                    var dMap: [String: ([UInt8], CoseKeyPrivate)] = [:]
                    
                    documents.forEach({
                        doc in
                        dMap[doc.0] = (doc.1, doc.2)
                    })
                    
                   
                    Proximity.shared.dataPresentation(allowed: allowed, items: items, documents: dMap)
                }
            }
            
            
            
        }
        .onAppear() {
            startScanning()
        }
        .alert(isPresented: Binding<Bool>(
            get: {
                if case .onError(let error) = proximityEvent {
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
        
        qrCode = Proximity.shared.start() ?? ""
        
//        LibIso18013Proximity.shared.setListener(viewModel)
//        do {
//            qrCode = try LibIso18013Proximity.shared.getQrCodePayload()
//            
//        } catch {
//            qrCode = "Error: \(error)"
//        }
    }
    
}

struct QRCodeView_Previews: PreviewProvider {
    static var previews: some View {
        QRCodeView()
    }
}
