//
//  CertTrustTests.swift
//  IOWalletProximity
//
//  Created by antoniocaparello on 09/07/25.
//


import XCTest
@testable import IOWalletProximity

internal import X509

class CertTrustTests: XCTestCase {
    
    static var verifierNotValid = "MIICbDCCAhKgAwIBAgIVANiDurMzb1sGghpFlLQITXBdInR7MAoGCCqGSM49BAMCMIHCMQswCQYDVQQGEwJJVDEOMAwGA1UECBMFTGF6aW8xDTALBgNVBAcTBFJvbWUxODA2BgNVBAoTL0lzdGl0dXRvIFBvbGlncmFmaWNvIGUgWmVjY2EgZGVsbG8gU3RhdG8gUy5QLkEuMQ0wCwYDVQQLEwRJUFpTMSQwIgYDVQQDExtwcmUudmVyaWZpZXIud2FsbGV0LmlwenMuaXQxJTAjBgkqhkiG9w0BCQEWFnByb3RvY29sbG9AcGVjLmlwenMuaXQwHhcNMjUwNzA5MDgwOTQ5WhcNMjUwNzEwMDgwOTUwWjBlMRQwEgYDVQQKEwtlVHVpdHVzIFNybDEzMAkGA1UECxMCSVQwJgYDVQQLEx9Qcm94aW1pdHkgVmVyaWZpY2F0aW9uIERlbW8gQXBwMRgwFgYDVQQDEw9kZXZpY2UtdXVpZC0xMjMwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAAQJWms5hWK/Yfx+ETCR523WJTbBicLg9ml5AJEQsQQC3FrdSIOutsJ4CQ3OLLuSvp4nmWxqA10FuqWZlhUslk6go0EwPzAOBgNVHQ8BAf8EBAMCBaAwDAYDVR0TAQH/BAIwADAfBgNVHSMEGDAWgBQ287nohTPktVG7aZu94XwPrFDj/DAKBggqhkjOPQQDAgNIADBFAiEAzvId5zoQiAxGbji4yuW9xPL4/QK6KZgV4uN8JWCOEgoCIAjh8D6bfcBKKIP8KGDumn71ChLxMZb6rplkR+CEMHuu"
    
    static var verifier = "MIICnzCCAkSgAwIBAgIUS+TqLYQpTMtQzOwWxcmdbBarJDowCgYIKoZIzj0EAwIwgcIxCzAJBgNVBAYTAklUMQ4wDAYDVQQIEwVMYXppbzENMAsGA1UEBxMEUm9tZTE4MDYGA1UEChMvSXN0aXR1dG8gUG9saWdyYWZpY28gZSBaZWNjYSBkZWxsbyBTdGF0byBTLlAuQS4xDTALBgNVBAsTBElQWlMxJDAiBgNVBAMTG3ByZS52ZXJpZmllci53YWxsZXQuaXB6cy5pdDElMCMGCSqGSIb3DQEJARYWcHJvdG9jb2xsb0BwZWMuaXB6cy5pdDAeFw0yNTA3MTUxMzA4MzVaFw0yNTA3MTYxMzA4MzZaMGUxFDASBgNVBAoTC2VUdWl0dXMgU3JsMTMwCQYDVQQLEwJJVDAmBgNVBAsTH1Byb3hpbWl0eSBWZXJpZmljYXRpb24gRGVtbyBBcHAxGDAWBgNVBAMTD2RldmljZS11dWlkLTEyMzBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABAgUeOPLm0Yj+cp0bMgIG0UbejRrYwt03DID0lsk9V/wAxkuwgsq3cTeep+V5gkOENnUt0QaUx79/gJH0VyZKFGjdDByMA4GA1UdDwEB/wQEAwIHgDASBgNVHSUECzAJBgcogYxdBQEGMAwGA1UdEwEB/wQCMAAwHQYDVR0OBBYEFJKiHgAfCwr0RPUSZt+0P5ld51fgMB8GA1UdIwQYMBaAFDbzueiFM+S1Ubtpm73hfA+sUOP8MAoGCCqGSM49BAMCA0kAMEYCIQCJQF0drNQ8p99GtgZUBkFqGjg3VlUSJf343fMRThWy2gIhANNHwzufDhJxPjNjlD55Ttx64njscoFUZEMgLwakrraO"
    
    static var rootCertBase64 = "MIIDQzCCAuigAwIBAgIGAZc6+XlDMAoGCCqGSM49BAMCMIGzMQswCQYDVQQGEwJJVDEOMAwGA1UECAwFTGF6aW8xDTALBgNVBAcMBFJvbWExMTAvBgNVBAoMKElzdGl0dXRvIFBvbGlncmFmaWNvIGUgWmVjY2EgZGVsbG8gU3RhdG8xCzAJBgNVBAsMAklUMR4wHAYDVQQDDBVwcmUudGEud2FsbGV0LmlwenMuaXQxJTAjBgkqhkiG9w0BCQEWFnByb3RvY29sbG9AcGVjLmlwenMuaXQwHhcNMjUwNjA0MTI0NTE3WhcNMzAwNjAzMTI0NTE3WjCBszELMAkGA1UEBhMCSVQxDjAMBgNVBAgMBUxhemlvMQ0wCwYDVQQHDARSb21hMTEwLwYDVQQKDChJc3RpdHV0byBQb2xpZ3JhZmljbyBlIFplY2NhIGRlbGxvIFN0YXRvMQswCQYDVQQLDAJJVDEeMBwGA1UEAwwVcHJlLnRhLndhbGxldC5pcHpzLml0MSUwIwYJKoZIhvcNAQkBFhZwcm90b2NvbGxvQHBlYy5pcHpzLml0MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEaE0xyhd3e9LDT7uwHOclL5H3389gwiCwFhI3KOvidn0glBIHYxqH+4Z9VTMYWG5L8cwC9AaJUCNGu2dp5ZiiTKOB5TCB4jAdBgNVHQ4EFgQU81CDcYxAqV3ptM8iKbJ06r9wxBkwHwYDVR0jBBgwFoAU81CDcYxAqV3ptM8iKbJ06r9wxBkwDwYDVR0TAQH/BAUwAwEB/zBEBggrBgEFBQcBAQQ4MDYwNAYIKwYBBQUHMAKGKGh0dHBzOi8vcHJlLnRhLndhbGxldC5pcHpzLml0L3BraS90YS5jZXIwDgYDVR0PAQH/BAQDAgEGMDkGA1UdHwQyMDAwLqAsoCqGKGh0dHBzOi8vcHJlLnRhLndhbGxldC5pcHpzLml0L3BraS90YS5jcmwwCgYIKoZIzj0EAwIDSQAwRgIhAOsQYzR+eGf4je63VGHqkpmkBbfyOre+mfIdHHowWWR/AiEA58xBNb5UW5uMB+tQur8fq24RD5MmRHLYS6bDgIYmluw="
    
    static var intermediateCertBase64 = "MIID2zCCA4GgAwIBAgIGAZe1/EqsMAoGCCqGSM49BAMCMIGzMQswCQYDVQQGEwJJVDEOMAwGA1UECAwFTGF6aW8xDTALBgNVBAcMBFJvbWExMTAvBgNVBAoMKElzdGl0dXRvIFBvbGlncmFmaWNvIGUgWmVjY2EgZGVsbG8gU3RhdG8xCzAJBgNVBAsMAklUMR4wHAYDVQQDDBVwcmUudGEud2FsbGV0LmlwenMuaXQxJTAjBgkqhkiG9w0BCQEWFnByb3RvY29sbG9AcGVjLmlwenMuaXQwHhcNMjUwNjI4MTAwMTM5WhcNMjcwNjI4MTAwMTM5WjCBwjELMAkGA1UEBhMCSVQxDjAMBgNVBAgTBUxhemlvMQ0wCwYDVQQHEwRSb21lMTgwNgYDVQQKEy9Jc3RpdHV0byBQb2xpZ3JhZmljbyBlIFplY2NhIGRlbGxvIFN0YXRvIFMuUC5BLjENMAsGA1UECxMESVBaUzEkMCIGA1UEAxMbcHJlLnZlcmlmaWVyLndhbGxldC5pcHpzLml0MSUwIwYJKoZIhvcNAQkBFhZwcm90b2NvbGxvQHBlYy5pcHpzLml0MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAESmYL3AUsTchFLid1pOEg+JvN2AljFoTlleeAOV/iQUhkqbLbUAgdplxSiE2Zh5BeCrhr6AYQFXbEInd4W99cNaOCAW4wggFqMB0GA1UdDgQWBBQ287nohTPktVG7aZu94XwPrFDj/DCB5QYDVR0jBIHdMIHagBTzUINxjECpXem0zyIpsnTqv3DEGaGBuaSBtjCBszELMAkGA1UEBhMCSVQxDjAMBgNVBAgMBUxhemlvMQ0wCwYDVQQHDARSb21hMTEwLwYDVQQKDChJc3RpdHV0byBQb2xpZ3JhZmljbyBlIFplY2NhIGRlbGxvIFN0YXRvMQswCQYDVQQLDAJJVDEeMBwGA1UEAwwVcHJlLnRhLndhbGxldC5pcHpzLml0MSUwIwYJKoZIhvcNAQkBFhZwcm90b2NvbGxvQHBlYy5pcHpzLml0ggYBlzr5eUMwEgYDVR0TAQH/BAgwBgEB/wIBADAOBgNVHQ8BAf8EBAMCAaYwPQYDVR0fBDYwNDAyoDCgLoYsaHR0cHM6Ly9wcmUudGEud2FsbGV0LmlwenMuaXQvcGtpL3RhLXN1Yi5jcmwwCgYIKoZIzj0EAwIDSAAwRQIhAPtgro6cUthvuuO15dUxepQxEel6KQkQkLYXcAG6mZeLAiAsR+SjlJNKLeTzEg0OdOtremJ1K+Q2BowcnIbEGbN+vA=="
    
    static var rootEudi64 = "MIIDHTCCAqOgAwIBAgIUVqjgtJqf4hUYJkqdYzi+0xwhwFYwCgYIKoZIzj0EAwMwXDEeMBwGA1UEAwwVUElEIElzc3VlciBDQSAtIFVUIDAxMS0wKwYDVQQKDCRFVURJIFdhbGxldCBSZWZlcmVuY2UgSW1wbGVtZW50YXRpb24xCzAJBgNVBAYTAlVUMB4XDTIzMDkwMTE4MzQxN1oXDTMyMTEyNzE4MzQxNlowXDEeMBwGA1UEAwwVUElEIElzc3VlciBDQSAtIFVUIDAxMS0wKwYDVQQKDCRFVURJIFdhbGxldCBSZWZlcmVuY2UgSW1wbGVtZW50YXRpb24xCzAJBgNVBAYTAlVUMHYwEAYHKoZIzj0CAQYFK4EEACIDYgAEFg5Shfsxp5R/UFIEKS3L27dwnFhnjSgUh2btKOQEnfb3doyeqMAvBtUMlClhsF3uefKinCw08NB31rwC+dtj6X/LE3n2C9jROIUN8PrnlLS5Qs4Rs4ZU5OIgztoaO8G9o4IBJDCCASAwEgYDVR0TAQH/BAgwBgEB/wIBADAfBgNVHSMEGDAWgBSzbLiRFxzXpBpmMYdC4YvAQMyVGzAWBgNVHSUBAf8EDDAKBggrgQICAAABBzBDBgNVHR8EPDA6MDigNqA0hjJodHRwczovL3ByZXByb2QucGtpLmV1ZGl3LmRldi9jcmwvcGlkX0NBX1VUXzAxLmNybDAdBgNVHQ4EFgQUs2y4kRcc16QaZjGHQuGLwEDMlRswDgYDVR0PAQH/BAQDAgEGMF0GA1UdEgRWMFSGUmh0dHBzOi8vZ2l0aHViLmNvbS9ldS1kaWdpdGFsLWlkZW50aXR5LXdhbGxldC9hcmNoaXRlY3R1cmUtYW5kLXJlZmVyZW5jZS1mcmFtZXdvcmswCgYIKoZIzj0EAwMDaAAwZQIwaXUA3j++xl/tdD76tXEWCikfM1CaRz4vzBC7NS0wCdItKiz6HZeV8EPtNCnsfKpNAjEAqrdeKDnr5Kwf8BA7tATehxNlOV4Hnc10XO1XULtigCwb49RpkqlS2Hul+DpqObUs"
    static var leafEudi64 = "MIIDBTCCAoygAwIBAgIUbNDW1PZAiJxwgAVQzFpkTHhaLqQwCgYIKoZIzj0EAwIwXDEeMBwGA1UEAwwVUElEIElzc3VlciBDQSAtIFVUIDAxMS0wKwYDVQQKDCRFVURJIFdhbGxldCBSZWZlcmVuY2UgSW1wbGVtZW50YXRpb24xCzAJBgNVBAYTAlVUMB4XDTI0MDIyNjAyNDEwM1oXDTI2MDIyNTAyNDEwMlowbDEgMB4GA1UEAwwXRVVESSBQcm94aW1pdHkgVmVyaWZpZXIxDDAKBgNVBAUTAzAwMTEtMCsGA1UECgwkRVVESSBXYWxsZXQgUmVmZXJlbmNlIEltcGxlbWVudGF0aW9uMQswCQYDVQQGEwJVVDBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABPQtRPyhV89nW6iam2/ie7yUV7rma0SK28E9wdIqJZ8G4sZW8DzI33lBPoic7TOoDmr46GdBRbAD2pNyjkr3ts+jggEaMIIBFjAMBgNVHRMBAf8EAjAAMB8GA1UdIwQYMBaAFLNsuJEXHNekGmYxh0Lhi8BAzJUbMBIGA1UdJQQLMAkGByiBjF0FAQYwQwYDVR0fBDwwOjA4oDagNIYyaHR0cHM6Ly9wcmVwcm9kLnBraS5ldWRpdy5kZXYvY3JsL3BpZF9DQV9VVF8wMS5jcmwwHQYDVR0OBBYEFLjTa1/kuIQKyCIjRDJs/6HuNRcgMA4GA1UdDwEB/wQEAwIHgDBdBgNVHRIEVjBUhlJodHRwczovL2dpdGh1Yi5jb20vZXUtZGlnaXRhbC1pZGVudGl0eS13YWxsZXQvYXJjaGl0ZWN0dXJlLWFuZC1yZWZlcmVuY2UtZnJhbWV3b3JrMAoGCCqGSM49BAMCA2cAMGQCMDboI4PfhaDoCoo8atE8srgEg0G5JRjCh3mnqxMFpDT4l4wXDnNm1EbcdPS5oROjbgIwJkjFM3nX79DU5v1AZd9sMAs0WK2NdigfOGgm5ivMAhxGCn2qk4DEq0jLdzrPgLne"
    
    
    static var verifierCert: SecCertificate {
        return SecCertificateCreateWithData(nil, Data(base64Encoded: verifier)! as CFData)!
    }
    
    static var rootCert: SecCertificate {
        return SecCertificateCreateWithData(nil, Data(base64Encoded: rootCertBase64)! as CFData)!
    }
    
    static var intermediateCert: SecCertificate {
        return SecCertificateCreateWithData(nil, Data(base64Encoded: intermediateCertBase64)! as CFData)!
    }
    
    static var verifierNotValidCert: SecCertificate {
        return SecCertificateCreateWithData(nil, Data(base64Encoded: verifierNotValid)! as CFData)!
    }
    
    static var eudiRootCert: SecCertificate {
        return SecCertificateCreateWithData(nil, Data(base64Encoded: rootEudi64)! as CFData)!
    }
    static var eudiVerifierCert: SecCertificate {
        return SecCertificateCreateWithData(nil, Data(base64Encoded: leafEudi64)! as CFData)!
    }
    
    
    static var chainCert: [SecCertificate] {
        return [
            rootCert,
            intermediateCert,
        ]
    }
    
    static var verifierChain: [SecCertificate] {
        return [
            intermediateCert,
            verifierCert
        ]
    }
    
    static var verifierNotValidChain: [SecCertificate] {
        return [
            verifierNotValidCert
        ]
    }
    
    static var certificateValidDate: Date {
        //2025-07-16 07:29:33 +0000
        return Date(timeIntervalSince1970: 1752650973)
    }
    
    /*func testEudiCertificateValidation() {
        let trustAnchor = [
            CertTrustTests.eudiRootCert
        ]
        
        let notTrusted = [
            CertTrustTests.eudiVerifierCert
        ]
        
        let isValid = SecurityHelpers.isMdocCertificateChainValid(secCertChain: notTrusted, usage: .mdocReaderAuth, rootCertsChains: [trustAnchor], date: CertTrustTests.certificateValidDate)
        
        print(isValid)
        
        XCTAssert(isValid.isValid)
        
    }*/
    
    func testCertificateValidation() {
        let trustAnchor = [
            CertTrustTests.rootCert
        ]
        
        let notTrusted = [
            CertTrustTests.verifierCert,
            CertTrustTests.intermediateCert
        ]
        
        let isValid = SecurityHelpers.isMdocCertificateChainValid(secCertChain: notTrusted, usage: .mdocReaderAuth, rootCertsChains: [trustAnchor], date: CertTrustTests.certificateValidDate)
        
        print(isValid)
        
        XCTAssert(isValid.isValid)
        
    }
    
    func testCertificateValidationWithTrustedIntermediates() {
        let trustAnchor = [
            CertTrustTests.rootCert,
            CertTrustTests.intermediateCert
        ]
        
        let notTrusted = [
            CertTrustTests.verifierCert,
        ]
        
        let isValid = SecurityHelpers.isMdocCertificateChainValid(secCertChain: notTrusted, usage: .mdocReaderAuth, rootCertsChains: [trustAnchor], date: CertTrustTests.certificateValidDate)
        
        print(isValid)
        
        XCTAssert(isValid.isValid)
        
    }
    
    func testCertificateValidationFailWithTrustedIntermediates() {
        let trustAnchor = [
            CertTrustTests.rootCert,
            CertTrustTests.intermediateCert
        ]
        
        let notTrusted = [
            CertTrustTests.verifierNotValidCert,
        ]
        
        let isValid = SecurityHelpers.isMdocCertificateChainValid(secCertChain: notTrusted, usage: .mdocReaderAuth, rootCertsChains: [trustAnchor], date: CertTrustTests.certificateValidDate)
        
        print(isValid)
        
        XCTAssert(!isValid.isValid)
        
    }
    
    func testCertificateValidationFail() {
        let trustAnchor = [
            CertTrustTests.rootCert,
        ]
        
        let notTrusted = [
            CertTrustTests.verifierNotValidCert,
            CertTrustTests.intermediateCert
        ]
        
        let isValid = SecurityHelpers.isMdocCertificateChainValid(secCertChain: notTrusted, usage: .mdocReaderAuth, rootCertsChains: [trustAnchor], date: CertTrustTests.certificateValidDate)
        
        print(isValid)
        
        XCTAssert(!isValid.isValid)
        
    }
}
