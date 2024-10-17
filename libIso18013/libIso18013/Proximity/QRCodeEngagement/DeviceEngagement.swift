//
//  DeviceEngagement.swift
//  libIso18013
//
//  Created by Martina D'urso on 15/10/24.
//


import Foundation
import SwiftCBOR
import CryptoKit

/// Struttura per rappresentare l'engagement del dispositivo
public struct DeviceEngagement {
    // Versione dell'implementazione
    static let versionImpl: String = "1.0"
    // Versione del dispositivo, inizializzata con la versione dell'implementazione
    var version: String = Self.versionImpl
    // Informazioni di sicurezza del dispositivo
    let security: Security
    // Metodi di recupero del dispositivo (opzionali)
    public var deviceRetrievalMethods: [DeviceRetrievalMethod]? = nil
    // Lista di stringhe riservate per usi futuri (rfus)
    var rfus: [String]?
    // Chiave privata del dispositivo (solo per il titolare)
    var d: [UInt8]?
    // Identificatore della chiave nel Secure Enclave
    var seKeyID: Data?
    // Codifica QR del dispositivo
    public var qrCoded: [UInt8]?
    
#if DEBUG
    // Funzioni per impostare la chiave privata e l'identificatore della chiave nel Secure Enclave per il debug
    mutating func setD(d: [UInt8]) { self.d = d }
    mutating func setKeyID(keyID: Data) { self.seKeyID = keyID }
#endif
    
    /// Genera il device engagement
    /// - Parameters:
    ///   - isBleServer: true per la modalità server BLE mdoc periferica, false per la modalità client centrale BLE mdoc
    ///   - crv: Il tipo di curva EC utilizzato nella chiave privata effimera mdoc
    ///   - rfus: Lista di stringhe riservate per usi futuri
    public init(isBleServer: Bool?, crv: ECCurveName = .p256, rfus: [String]? = nil) {
        let pk: CoseKeyPrivate
        // Se il Secure Enclave è disponibile e la curva è p256, crea una chiave privata nel Secure Enclave
        if SecureEnclave.isAvailable, crv == .p256, let se = try? SecureEnclave.P256.KeyAgreement.PrivateKey() {
            pk = CoseKeyPrivate(publicKeyx963Data: se.publicKey.x963Representation, secureEnclaveKeyID: se.dataRepresentation)
            seKeyID = se.dataRepresentation
        } else {
            // Altrimenti, crea una chiave privata normale
            pk = CoseKeyPrivate(crv: crv)
            d = pk.d
        }
        security = Security(deviceKey: pk.key)
        self.rfus = rfus
        // Aggiungi il metodo di recupero BLE se specificato
        if let isBleServer {
            deviceRetrievalMethods = [.ble(isBleServer: isBleServer, uuid: DeviceRetrievalMethod.getRandomBleUuid())]
        }
    }
    
    /// Inizializza il device engagement dai dati CBOR
    public init?(data: [UInt8]) {
        guard let obj = try? CBOR.decode(data) else { return nil }
        self.init(cbor: obj)
    }
    
    /// Restituisce la chiave privata del dispositivo, se disponibile
    public var privateKey: CoseKeyPrivate? {
        if let seKeyID {
            return CoseKeyPrivate(publicKeyx963Data: security.deviceKey.getx963Representation(), secureEnclaveKeyID: seKeyID)
        } else if let d {
            return CoseKeyPrivate(key: security.deviceKey, d: d)
        }
        return nil
    }
    
    /// Verifica se il dispositivo è in modalità server BLE
    public var isBleServer: Bool? {
        guard let deviceRetrievalMethods else { return nil }
        for case let .ble(isBleServer, _) in deviceRetrievalMethods {
            return isBleServer
        }
        return nil
    }
    
    /// Restituisce l'UUID del BLE, se disponibile
    public var ble_uuid: String? {
        guard let deviceRetrievalMethods else { return nil }
        for case let .ble(_, uuid) in deviceRetrievalMethods {
            return uuid
        }
        return nil
    }
}

// Estensione per supportare la codifica CBOR
extension DeviceEngagement: CBOREncodable {
    public func toCBOR(options: SwiftCBOR.CBOROptions) -> SwiftCBOR.CBOR {
        var res = CBOR.map([0: .utf8String(version), 1: security.toCBOR(options: options)])
        if let drms = deviceRetrievalMethods {
            res[2] = .array(drms.map { $0.toCBOR(options: options) })
        }
        if let rfus = self.rfus {
            for (i, r) in rfus.enumerated() {
                res[.negativeInt(UInt64(i))] = .utf8String(r)
            }
        }
        return res
    }
}

// Estensione per supportare la decodifica CBOR
extension DeviceEngagement: CBORDecodable {
    public init?(cbor: CBOR) {
        guard case let .map(map) = cbor else { return nil }
        guard let cv = map[0], case let .utf8String(v) = cv, v.prefix(2) == "1." else { return nil }
        guard let cs = map[1], let s = Security(cbor: cs) else { return nil }
        if let cdrms = map[2], case let .array(drms) = cdrms, drms.count > 0 {
            deviceRetrievalMethods = drms.compactMap(DeviceRetrievalMethod.init(cbor:))
        }
        version = v
        security = s
    }
}

extension DeviceEngagement {
    /// Genera la stringa del codice QR da `qrCoded`
    var qrCode: String {
        "mdoc:" + Data(qrCoded!).base64URLEncodedString()
    }
    
    /// Crea il payload per il codice QR
    /// - Returns: Una stringa rappresentante il payload del codice QR
    public mutating func getQrCodePayload() -> String {
        qrCoded = encode(options: CBOROptions())
        return qrCode
    }
}
