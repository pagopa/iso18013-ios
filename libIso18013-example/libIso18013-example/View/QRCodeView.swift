//
//  QRCodeView.swift
//  libIso18013-example
//
//  Created by Martina D'urso on 09/10/24.
//

import SwiftUI

struct QRCodeView: View {
    var body: some View {
        VStack {
            Spacer()
            QRCode()
                .generateQRCode(from: "example")
                .resizable()
                .frame(width: 200, height: 200)
            Spacer()
        }
    }
}

struct QRCodeView_Previews: PreviewProvider {
    static var previews: some View {
        QRCodeView()
    }
}
