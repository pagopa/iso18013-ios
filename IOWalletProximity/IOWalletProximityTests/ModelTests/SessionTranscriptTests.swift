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
    func testSessionTranscriptOID4VP() {
        let clientId = "RANDOM CLIENT ID"
        let responseUri = "RANDOM URI"
        let authorizationRequestNonce = "AUTH NONCE"
        let mdocNonce = "MDOC NONCE"
        
        let generatedOid4vpSessionTranscript = "g/b2g1ggxUpjPEK7GoBmVsdwEzkQzlL9Kjd16xaMk4qmS5XhMlFYIPQlZ089PEspsVYm/PjJRfWZ5wLXMFiD8onG/RgRbhPLakFVVEggTk9OQ0U="
        
        let oid4vpSessionTranscript = Proximity().generateOID4VPSessionTranscriptCBOR(
            clientId: clientId,
            responseUri: responseUri,
            authorizationRequestNonce: authorizationRequestNonce,
            mdocGeneratedNonce: mdocNonce
        )
        
        XCTAssertEqual(Data(oid4vpSessionTranscript).base64EncodedString(), generatedOid4vpSessionTranscript)
        
        let decodedOid4vpSessionTranscript = SessionTranscript(data: oid4vpSessionTranscript)
        
        guard case .array(let handOver) = decodedOid4vpSessionTranscript?.handOver else {
            XCTFail("failed to decode handOver")
            return
        }
        
        guard case .utf8String(let decodedAuthorizationRequestNonce) = handOver[2] else {
            XCTFail("failed to decode authorizationRequestNonce")
            return
        }
        
        XCTAssertEqual(decodedAuthorizationRequestNonce, authorizationRequestNonce)
    }
}
