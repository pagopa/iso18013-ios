//
//  QRCodeTests.swift
//  libIso18013-example
//
//  Created by Martina D'urso on 09/10/24.
//

import XCTest
import CoreImage.CIFilterBuiltins
import SwiftUI
@testable import libIso18013_example

// Unit tests for the QRCode class
class QRCodeTests: XCTestCase {
    func testQRCodeGeneration() {
        let qrCodeGenerator = QRCode()
        let qrImage = qrCodeGenerator.generateQRCode(from: "test")
        
        // Verify the image is not the default error image
        XCTAssertNotEqual(qrImage, Image(systemName: "xmark.circle"), "The QR code image should not be the default error image.")
    }
    
    func testEmptyStringQRCode() {
        let qrCodeGenerator = QRCode()
        let qrImage = qrCodeGenerator.generateQRCode(from: "")
        
        // Verify the image is still generated even for an empty string
        XCTAssertNotEqual(qrImage, Image(systemName: "xmark.circle"), "The QR code image should not be the default error image for an empty string.")
    }
    
    func testQRCodeWithSpecialCharacters() {
        let qrCodeGenerator = QRCode()
        let qrImage = qrCodeGenerator.generateQRCode(from: "@#$%^&*()_+")
        
        // Verify the image is not the default error image for special characters
        XCTAssertNotEqual(qrImage, Image(systemName: "xmark.circle"), "The QR code image should not be the default error image for special characters.")
    }
    
    func testQRCodeWithLongString() {
        let qrCodeGenerator = QRCode()
        let longString = String(repeating: "a", count: 1000)
        let qrImage = qrCodeGenerator.generateQRCode(from: longString)
        
        // Verify the image is not the default error image for a long string
        XCTAssertNotEqual(qrImage, Image(systemName: "xmark.circle"), "The QR code image should not be the default error image for a long string.")
    }
    
    func testQRCodeGenerationPerformance() {
        let qrCodeGenerator = QRCode()
        self.measure {
            _ = qrCodeGenerator.generateQRCode(from: "performance test")
        }
    }
}
