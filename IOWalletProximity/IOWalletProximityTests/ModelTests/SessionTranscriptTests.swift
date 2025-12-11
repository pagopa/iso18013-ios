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
        let jwkThumbprint = "JWK thumbprint"
        
        let generatedOid4vpSessionTranscript = "g/b2gnFPcGVuSUQ0VlBIYW5kb3ZlclggCRfhg/rggKdSDEm4LKN59PF2I/aPseQugYG3S0KBcsQ="
        
        let oid4vpSessionTranscript = Proximity().generateOID4VPSessionTranscriptCBOR(
            clientId: clientId,
            responseUri: responseUri,
            authorizationRequestNonce: authorizationRequestNonce,
            jwkThumbprint: jwkThumbprint
        )
        
        XCTAssertEqual(Data(oid4vpSessionTranscript).base64EncodedString(), generatedOid4vpSessionTranscript)
        
        let decodedOid4vpSessionTranscript = SessionTranscript(data: oid4vpSessionTranscript)
        
        guard case .array(let handOver) = decodedOid4vpSessionTranscript?.handOver else {
            XCTFail("failed to decode handOver")
            return
        }
        
        guard case .utf8String(let openID4VPHandover) = handOver[0] else {
            XCTFail("failed to decode openID4VPHandover")
            return
        }
        
        XCTAssertEqual(openID4VPHandover, "OpenID4VPHandover")
    }
}
