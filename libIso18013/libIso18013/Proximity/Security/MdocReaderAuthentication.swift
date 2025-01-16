//
//  MdocReaderAuthentication.swift
//  libIso18013
//
//  Created by Antonio on 17/10/24.
//

import Foundation
import CryptoKit
import SwiftCBOR

/// Implements mdoc reader authentication
///
/// The data that the mdoc reader authenticates is the ReaderAuthentication structure
/// Currently the mdoc side is implemented (verification of reader-auth CBOR data)
public struct MdocReaderAuthentication {
    
    // Stores the transcript of the session, used for verification
    let transcript: SessionTranscript
    
    /// Validate the reader auth structure contained in the reader's initial message
    /// - Parameters:
    ///   - readerAuthCBOR: An untagged COSE-Sign1 structure containing the signature
    ///   - readerAuthCertificate: The reader auth certificate decoded from above reader-auth structure. Contains the mdoc reader public key
    ///   - itemsRequestRawData: Reader's item request raw data
    ///   - rootCerts: Optional array of root certificates for additional validation
    /// - Returns: A tuple containing a boolean indicating if the validation succeeded, and an optional failure reason
    public func validateReaderAuth(readerAuthCBOR: CBOR, readerAuthCertificate: Data, itemsRequestRawData: [UInt8], rootCerts: [SecCertificate]? = nil) throws -> (Bool, String?) {
        // Create a ReaderAuthentication object using the session transcript and request data
        let ra = ReaderAuthentication(sessionTranscript: transcript, itemsRequestRawData: itemsRequestRawData)
        
        // Encode the ReaderAuthentication object to CBOR format
        let contentBytes = ra.toCBOR(options: CBOROptions()).taggedEncoded.encode(options: CBOROptions())
        
        // Create a certificate object from the readerAuthCertificate data
        guard let sc = SecCertificateCreateWithData(nil, Data(readerAuthCertificate) as CFData) else {
            return (false, "Invalid reader Auth Certificate")
        }
        
        // Create a COSE object to represent the reader's authentication signature
        guard let readerAuth = Cose(type: .sign1, cbor: readerAuthCBOR) else {
            return (false, "Invalid reader auth CBOR")
        }
        
        // Extract the public key from the certificate
        guard let publicKeyx963 = sc.getPublicKey() else {
            return (false, "Public key not found in certificate")
        }
        
        // Validate the COSE-Sign1 signature using the public key and the ReaderAuthentication data
        let isSignatureValid = try readerAuth.validateDetachedCoseSign1(payloadData: Data(contentBytes), publicKey_x963: publicKeyx963)
        
        // If no root certificates are provided, return the result of signature validation
        guard let rootCerts = rootCerts else { return (isSignatureValid, nil) }
        
        // Validate the reader authentication certificate using root certificates
        let certValidationResult = SecurityHelpers.isMdocCertificateValid(secCert: sc, usage: .mdocReaderAuth, rootCerts: rootCerts)
        
        // If the certificate validation failed, log warning messages (logging currently commented out)
        if !certValidationResult.isValid {
            //logger.warning(Logger.Message(unicodeScalarLiteral: certValidationResult.validationMessages.joined(separator: "\n")))
        }
        
        // Return the combined result of signature validation and certificate validation messages
        return (isSignatureValid, certValidationResult.validationMessages.joined(separator: "\n"))
    }
    
    /// Initializes the MdocReaderAuthentication with a given session transcript
    /// - Parameter transcript: The session transcript that provides context for the reader authentication
    public init(transcript: SessionTranscript) {
        self.transcript = transcript
    }
}
