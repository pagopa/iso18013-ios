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
    
    @StateObject private var viewModel: QRCodeViewModel = QRCodeViewModel()
    @State var qrCode: String = ""
    
    var body: some View {
        ZStack {
            VStack {
                Spacer()
                if case .success = viewModel.state {
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
                        viewModel.state = .idle
                    }
                } else {
                    QRCode
                        .getQrCodeImage(qrCode: qrCode, inputCorrectionLevel: .m)
                        .resizable()
                        .frame(width: 200, height: 200)
                }
                Spacer()
            }
            if case .loading = viewModel.state {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                ProgressView()
                    .tint(Color.blue)
                    .scaleEffect(4)
            }
        }
        .onAppear() {
            startScanning()
        }
        .overlay(content: {
            viewModel.onRequest.map({
                item in
                    DeviceRequestAlert(requested: viewModel.buildAlert(item: item.deviceRequest)) { allowed, items in
                        viewModel.sendResponse(allowed: allowed, items: items, onResponse: item.onResponse!)
                }
            })
        })
        .alert(isPresented: Binding<Bool>(
            get: {
                if case .failure(_) = viewModel.state {
                    return true
                } else {
                    return false
                }
            },
            set: { _ in }
        )) {
            Alert(title: Text("Error"), message: Text(({
                if case let .failure(message) = viewModel.state {
                    return message
                } else {
                    return "Si è verificato un errore."
                }
            })()), dismissButton: .default(Text("OK")))
        }
    }
    
    func startScanning() {
        LibIso18013Proximity.shared.setListener(viewModel)
        do {
            qrCode = try LibIso18013Proximity.shared.getQrCodePayload()
            
        } catch {
            qrCode = "Error: \(error)"
        }
    }

}

struct QRCodeView_Previews: PreviewProvider {
    static var previews: some View {
        QRCodeView()
    }
}
