//
//  QRCodeTests.swift
//  libIso18013-example
//
//  Created by Martina D'urso on 09/10/24.
//

import XCTest
import CoreImage.CIFilterBuiltins
import SwiftUI
@testable import IOWalletProximityExample

// Unit tests for the QRCode class
class QRCodeTests: XCTestCase {
    func testQRCodeGeneration() {
        let qrImage = QRCode.getQrCodeImage(qrCode: "test")
        
        // Verify the image is not the default error image
        XCTAssertNotEqual(qrImage, Image(systemName: "xmark.circle"), "The QR code image should not be the default error image.")
    }
    
    func testEmptyStringQRCode() {
        let qrImage = QRCode.getQrCodeImage(qrCode: "")
        
        // Verify the image is still generated even for an empty string
        XCTAssertNotEqual(qrImage, Image(systemName: "xmark.circle"), "The QR code image should not be the default error image for an empty string.")
    }
    
    func testQRCodeWithSpecialCharacters() {
        let qrImage = QRCode.getQrCodeImage(qrCode: "@#$%^&*()_+")
        
        // Verify the image is not the default error image for special characters
        XCTAssertNotEqual(qrImage, Image(systemName: "xmark.circle"), "The QR code image should not be the default error image for special characters.")
    }
    
    func testQRCodeWithLongString() {
        let longString = String(repeating: "a", count: 1000)
        let qrImage = QRCode.getQrCodeImage(qrCode: longString)
        
        // Verify the image is not the default error image for a long string
        XCTAssertNotEqual(qrImage, Image(systemName: "xmark.circle"), "The QR code image should not be the default error image for a long string.")
    }
    
    func testQRCodeGenerationPerformance() {
        self.measure {
            _ = QRCode.getQrCodeImage(qrCode: "performance test")
        }
    }
}
