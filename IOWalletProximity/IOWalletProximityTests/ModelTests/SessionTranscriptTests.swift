//
//  SessionTranscriptTests.swift
//  IOWalletProximity
//
//  Created by Antonio Caparello on 20/03/25.
//

import XCTest
import Security
internal import SwiftCBOR

@testable import IOWalletProximity

class SessionTranscriptTests: XCTestCase {
    /// Example of OpenID4VP 1.0 Appendix B.2.6.1
    func testSessionTranscriptOID4VP() {
        let clientId = "x509_san_dns:example.com"
        let responseUri = "https://example.com/response"
        let authorizationRequestNonce = "exc7gBkxjx1rdc9udRrveKvSsJIq80avlXeLHhGwqtA"
        let jwkThumbprint = hexToBytes("4283ec927ae0f208daaa2d026a814f2b22dca52cf85ffa8f3f8626c6bd669047")
        
        let expectedOid4vpSessionTranscript = "83f6f682714f70656e494434565048616e646f7665725820048bc053c00442af9b8eed494cefdd9d95240d254b046b11b68013722aad38ac"
        
        let oid4vpSessionTranscript = Proximity().generateOID4VPSessionTranscriptCBOR(
            clientId: clientId,
            responseUri: responseUri,
            authorizationRequestNonce: authorizationRequestNonce,
            jwkThumbprint: jwkThumbprint
        )
        
        XCTAssertEqual(oid4vpSessionTranscript.map { String(format: "%02x", $0) }.joined(), expectedOid4vpSessionTranscript)
        
        let decodedOid4vpSessionTranscript = try? SessionTranscript(data: oid4vpSessionTranscript)
        
        guard case .array(let handOver) = decodedOid4vpSessionTranscript?.handOver else {
            XCTFail("failed to decode handOver")
            return
        }
        
        guard case .utf8String(let identifier) = handOver[0] else {
            XCTFail("failed to decode handover identifier")
            return
        }
        
        XCTAssertEqual(identifier, "OpenID4VPHandover")
    }
    
    private func hexToBytes(_ hex: String) -> [UInt8] {
        stride(from: 0, to: hex.count, by: 2).map {
            let start = hex.index(hex.startIndex, offsetBy: $0)
            return UInt8(hex[start..<hex.index(start, offsetBy: 2)], radix: 16)!
        }
    }
}
