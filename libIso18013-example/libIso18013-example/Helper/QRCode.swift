//
//  QRCode.swift
//  libIso18013-example
//
//  Created by Martina D'urso on 10/10/24.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

// QRCode class that contains the QR code generation logic
class QRCode {
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    
    func generateQRCode(from text: String) -> Image {
        // Default image to display in case of failure
        var qrImage = Image(systemName: "xmark.circle")
        
        // Convert the input text to data
        let data = Data(text.utf8)
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("Q", forKey: "inputCorrectionLevel")
        
        // Scale the output image
        let transform = CGAffineTransform(scaleX: 20, y: 20)
        
        // Generate the QR code and convert it to a UIImage
        if let outputImage = filter.outputImage?.transformed(by: transform) {
            if let image = context.createCGImage(outputImage, from: outputImage.extent) {
                qrImage = Image(uiImage: UIImage(cgImage: image))
            }
        }
        return qrImage
    }
}
