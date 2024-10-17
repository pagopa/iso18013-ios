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
            LibIso18013Proximity.shared.setListner(viewModel)
            do {
                qrCode = try LibIso18013Proximity.shared.getQrCodePayload()
            } catch {
                qrCode = "Error: \(error)"
            }
        }
    }
}

class QRCodeViewModel: QrEngagementListener {
    func onConnecting() {
        
    }
    
}

struct QRCodeView_Previews: PreviewProvider {
    static var previews: some View {
        QRCodeView()
    }
}
