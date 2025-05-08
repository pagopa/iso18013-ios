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
    let mdocGeneratedNonce: String
    
    func toCBOR(options: SwiftCBOR.CBOROptions) -> SwiftCBOR.CBOR {
        let encodedClientId = CBOR(arrayLiteral:
            .utf8String(clientId),
            .utf8String(mdocGeneratedNonce)
        ).encode()
        
        let encodedResponseUri = CBOR(arrayLiteral:
            .utf8String(responseUri),
            .utf8String(mdocGeneratedNonce)
        ).encode()
        
        let clientIdChecksum = calcSHA256Hash(encodedClientId)
        let responseUriChecksum = calcSHA256Hash(encodedResponseUri)
        
        return CBOR(arrayLiteral:
            .byteString(clientIdChecksum),
            .byteString(responseUriChecksum),
            .utf8String(authorizationRequestNonce)
        )
    }
    
    func calcSHA256Hash( _ data: [UInt8] ) -> [UInt8] {
        var sha256 = SHA256()
        sha256.update(data: data)
        let hash = sha256.finalize()
        
        return Array(hash)
    }
    
}
