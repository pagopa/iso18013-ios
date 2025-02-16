//
//  SecurityHelpers.swift
//  libIso18013
//
//  Created by Antonio on 17/10/24.
//

import X509
import CryptoKit

public class SecurityHelpers {
    public static var nonAllowedExtensions: [String] = NotAllowedExtension.allCases.map(\.rawValue)
    
    public static func isMdocCertificateValid(secCert: SecCertificate, usage: CertificateUsage, rootCerts: [SecCertificate]) -> (isValid: Bool, validationMessages: [String], rootCert: SecCertificate?) {
        let now = Date()
        var messages = [String]()
        var trust: SecTrust?
        let policy = SecPolicyCreateBasicX509()
        _ = SecTrustCreateWithCertificates(secCert, policy, &trust)
        guard let trust = trust else { return (false, ["Not valid certificate for \(usage)"], nil) }
        
        let secData: Data = SecCertificateCopyData(secCert) as Data
        guard let x509Cert = try? X509.Certificate(derEncoded: [UInt8](secData)) else { return (false, ["Not valid certificate for \(usage)"], nil) }
        guard x509Cert.notValidBefore <= now, now <= x509Cert.notValidAfter else { return (false, ["Current date not in validity period of Certificate"], nil) }
        
        let validityDays = Calendar.current.dateComponents([.day], from: x509Cert.notValidBefore, to: x509Cert.notValidAfter).day
        guard let validityDays, validityDays > 0 else { return (false, ["Invalid validity period"], nil) }
        guard !x509Cert.subject.isEmpty, let cn = getCommonName(ref: secCert), !cn.isEmpty else { return (false, ["Missing Common Name of Reader Certificate"], nil) }
        guard !x509Cert.signature.description.isEmpty else { return (false, ["Missing Signature data"], nil) }
        
        if x509Cert.serialNumber.description.isEmpty { messages.append("Missing Serial number") }
        if x509Cert.hasDuplicateExtensions() { messages.append("Duplicate extensions in Certificate") }
        
        if usage == .mdocReaderAuth {
            verifyReaderAuthCert(x509Cert, messages: &messages)
        }
        
        SecTrustSetPolicies(trust, policy)
        for cert in rootCerts {
            let certArray = [cert]
            SecTrustSetAnchorCertificates(trust, certArray as CFArray)
            SecTrustSetAnchorCertificatesOnly(trust, true)
            if trustIsValid(trust) {
                guard let x509root = try? X509.Certificate(derEncoded: [UInt8](SecCertificateCopyData(cert) as Data)) else { return (false, ["Bad root certificate"], cert) }
                guard x509root.notValidBefore <= now, now <= x509root.notValidAfter else { return (false, ["Current date not in validity period of Reader Root Certificate"], nil) }
                
                if usage == .mdocReaderAuth, let rootGns = x509root.getSubjectAlternativeNames(), let gns = x509Cert.getSubjectAlternativeNames() {
                    guard gns.elementsEqual(rootGns) else {
                        return (false, ["Issuer data rfc822Name or uniformResourceIdentifier do not match with root cert."], nil)
                    }
                }
                
                if x509Cert.serialNumber == x509root.serialNumber { continue }
                let crlSerialNumbers = fetchCRLSerialNumbers(x509root)
                if !crlSerialNumbers.isEmpty {
                    if crlSerialNumbers.contains(x509Cert.serialNumber) { return (false, ["Revoked Certificate for \(cn)"], cert) }
                    if crlSerialNumbers.contains(x509root.serialNumber) { return (false, ["Revoked Root Certificate for \(getCommonName(ref: cert) ?? "")"], cert) }
                }
                return (true, messages, cert)
            }
        }
        
        messages.insert("Certificate not matched with root certificates", at: 0)
        return (false, messages, nil)
    }
    
    public static func trustIsValid(_ trust: SecTrust) -> Bool {
        var error: CFError?
        return SecTrustEvaluateWithError(trust, &error)
    }
    
    public static func fetchCRLSerialNumbers(_ x509root: X509.Certificate) -> [Certificate.SerialNumber] {
        var serialNumbers = [Certificate.SerialNumber]()
        if let ext = x509root.extensions[oid: .X509ExtensionID.cRLDistributionPoints],
           let crlDistribution = try? CRLDistributions(derEncoded: ext.value) {
            for crl in crlDistribution.crls {
                guard let crlUrl = URL(string: crl.distributionPoint),
                      let pem = try? String(contentsOf: crlUrl),
                      let crl = try? CRL(pemEncoded: pem) else { continue }
                serialNumbers.append(contentsOf: crl.revokedSerials.map(\.serial))
            }
        }
        return serialNumbers
    }
    
    public static func verifyReaderAuthCert(_ x509: X509.Certificate, messages: inout [String]) {
        if x509.issuer.isEmpty { messages.append("Missing Issuer") }
        if let ext_aki = try? x509.extensions.authorityKeyIdentifier, let ext_aki_ki = ext_aki.keyIdentifier, ext_aki_ki.isEmpty {
            messages.append("Missing Authority Key Identifier")
        }
        
        let pkData = Array(x509.publicKey.subjectPublicKeyInfoBytes)
        if let ext_ski = try? x509.extensions.subjectKeyIdentifier {
            let ski = Array(ext_ski.keyIdentifier)
            if ski != Array(Insecure.SHA1.hash(data: pkData)) {
                messages.append("Wrong Subject Key Identifier")
            }
        } else {
            messages.append("Missing Subject Key Identifier")
        }
        
        if let keyUsage = try? x509.extensions.keyUsage, !keyUsage.digitalSignature {
            messages.append("Key usage should be verifying Digital Certificate")
        }
        
        if let extKeyUsage = try? x509.extensions.extendedKeyUsage,
           !extKeyUsage.contains(ExtendedKeyUsage.Usage(oid: .extKeyUsageMdlReaderAuth)) {
            messages.append("Extended Key usage does not contain mdlReaderAuth")
        }
        
        if !x509.signatureAlgorithm.isECDSA256or384or512 {
            messages.append("Signature algorithm must be ECDSA with SHA 256/384/512")
        }
        
        let criticalExtensionOIDs: [String] = x509.extensions.filter(\.critical).map(\.oid).map(\.description)
        let notAllowedCriticalExt = Set(criticalExtensionOIDs).intersection(Set(Self.nonAllowedExtensions))
        if !notAllowedCriticalExt.isEmpty {
            messages.append("Not allowed critical extensions \(notAllowedCriticalExt)")
        }
        
        if let crlExt1 = x509.extensions[oid: .X509ExtensionID.cRLDistributionPoints],
           let crlExt2 = try? CRLDistributionPointsExtension(crlExt1), crlExt2.crls.isEmpty {
            messages.append("Missing CRL Distribution extension")
        }
    }
    
    public static func getCommonName(ref: SecCertificate) -> String? {
        var cfName: CFString?
        SecCertificateCopyCommonName(ref, &cfName)
        return cfName as String?
    }
}
