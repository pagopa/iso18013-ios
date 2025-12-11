//
//  OID4VPHandover.swift
//  IOWalletProximity
//
//  Created by Antonio Caparello on 20/03/25.
//

internal import SwiftCBOR
internal import Crypto

struct OID4VPHandover : CBOREncodable {
    let clientId: String
    let responseUri: String
    let authorizationRequestNonce: String
    let jwkThumbprint: String?

    func toCBOR(options: CBOROptions) -> CBOR {
        // Encode jwkThumbprint or null
        let jwkThumbprintCBOR: CBOR = {
            if let thumb = jwkThumbprint, let decoded = Data(base64URLEncoded: thumb) {
                return .byteString(Array(decoded))
            } else {
                return .null                            
            }
        }()

        // OpenID4VPHandoverInfo
        let handoverInfoCBOR = CBOR(arrayLiteral:
            .utf8String(clientId),
            .utf8String(authorizationRequestNonce),
            jwkThumbprintCBOR,
            .utf8String(responseUri)
        )

        let handoverInfoBytes = handoverInfoCBOR.encode()

        // OpenID4VPHandoverInfoHash
        let infoHash = calcSHA256Hash(handoverInfoBytes)

        return CBOR(arrayLiteral:
            .utf8String("OpenID4VPHandover"),
            .byteString(infoHash)
        )
    }

    private func calcSHA256Hash(_ data: [UInt8]) -> [UInt8] {
        var sha = SHA256()
        sha.update(data: data)
        return Array(sha.finalize())
    }
}