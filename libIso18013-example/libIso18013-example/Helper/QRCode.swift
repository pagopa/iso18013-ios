//
//  QRCode.swift
//  libIso18013-example
//
//  Created by Martina D'urso on 10/10/24.
//

import SwiftUI
import CoreImage.CIFilterBuiltins
import Combine


///// Enum per rappresentare il livello di correzione dell'input per il codice QR
public enum InputCorrectionLevel: Int {
    /// L: 7% della capacità di correzione degli errori
    case l = 0
    /// M: 15% della capacità di correzione degli errori
    case m = 1
    /// Q: 25% della capacità di correzione degli errori
    case q = 2
    /// H: 30% della capacità di correzione degli errori
    case h = 3
}

// QRCode class that contains the QR code generation logic
class QRCode {
    
    /// Creates a CIImage of the QR code
    /// - Parameters:
    ///   - qrCode: The QR code string to be converted into an image
    ///   - inputCorrectionLevel: The input correction level for the QR code (default: `.m`)
    /// - Returns: A UIImage representing the QR code, or `nil` if generation fails
    static func getQrCodeImage(qrCode: String, inputCorrectionLevel: InputCorrectionLevel = .m) -> Image {
        // Default image to display in case of failure
        var qrImage = Image(systemName: "xmark.circle")
        
        // Converts the QR code string into data
        guard let stringData = qrCode.data(using: .utf8) else { return qrImage }
        
        // Gets the input correction level as a string
        let correctionLevel = ["L", "M", "Q", "H"][inputCorrectionLevel.rawValue]
        
        // Creates the CIFilter to generate the QR code
        guard let qrFilter = CIFilter(name: "CIQRCodeGenerator") else { return qrImage }
        qrFilter.setDefaults()
        qrFilter.setValue(stringData, forKey: "inputMessage")
        qrFilter.setValue(correctionLevel, forKey: "inputCorrectionLevel")
        
        // Applies a transformation to increase the size of the QR image
        let transform = CGAffineTransform(scaleX: 6, y: 6)
        
        // Creates a CIContext to convert the CIImage into a CGImage
        let context = CIContext()
        
        // Generate the QR code and convert it to a UIImage
        if let outputImage = qrFilter.outputImage?.transformed(by: transform) {
            if let image = context.createCGImage(outputImage, from: outputImage.extent) {
                qrImage = Image(uiImage: UIImage(cgImage: image))
            }
        }
        return qrImage
    }
}

