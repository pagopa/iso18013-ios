//
//  CoseKeyPrivate.swift
//  libIso18013
//
//  Created by Antonio on 03/10/24.
//

import CryptoKit
import SwiftCBOR


// CoseKey + private key
public struct CoseKeyPrivate  {
  
  public let key: CoseKey
  let d: [UInt8]
  public let secureEnclaveKeyID: Data?
  
  public init(key: CoseKey, d: [UInt8]) {
    self.key = key
    self.d = d
    self.secureEnclaveKeyID = nil
  }
}

extension CoseKeyPrivate {
  // make new key
  public init(crv: ECCurveName) {
    var privateKeyx963Data: Data
    switch crv {
    case .p256:
      let key = P256.KeyAgreement.PrivateKey(compactRepresentable: false)
      privateKeyx963Data = key.x963Representation
    case .p384:
      let key = P384.KeyAgreement.PrivateKey(compactRepresentable: false)
      privateKeyx963Data = key.x963Representation
    case .p521:
      let key = P521.KeyAgreement.PrivateKey(compactRepresentable: false)
      privateKeyx963Data = key.x963Representation
      
      //    case .x25519, .ed25519:
      //      let key = Curve25519.KeyAgreement.PrivateKey()
      //      privateKeyx963Data = key.rawRepresentation
      
    }
    
    switch crv {
      //    case .x25519, .ed25519:
      //      self.init(privateKeyRawData: privateKeyx963Data, crv: crv)
    case .p256, .p384, .p521:
      self.init(privateKeyx963Data: privateKeyx963Data, crv: crv)
    }
    
    
  }
  
  
  //  public init(publicKeyRawData: Data, crv: ECCurveName = .ed25519) {
  //    //MARK: check if is OKP
  //    key = CoseKey(crv: crv, kty: crv.keyType, x: [UInt8](publicKeyRawData), y: [])
  //    d = []
  //    secureEnclaveKeyID = nil
  //  }
  //
  //  public init(privateKeyRawData: Data, crv: ECCurveName = .ed25519) {
  //    //MARK: check if is OKP
  //    key = CoseKey(crv: crv, kty: crv.keyType, x: [], y: [])
  //    d = [UInt8](privateKeyRawData)
  //    secureEnclaveKeyID = nil
  //
  //  }
  
  
  public init(privateKeyx963Data: Data, crv: ECCurveName = .p256) {
    //MARK: check if is EC2
    
    let xyk = privateKeyx963Data.advanced(by: 1) //Data(privateKeyx963Data[1...])
    let klen = xyk.count / 3
    let xdata: Data = Data(xyk[0..<klen])
    let ydata: Data = Data(xyk[klen..<2 * klen])
    let ddata: Data = Data(xyk[2 * klen..<3 * klen])
    key = CoseKey(crv: crv, kty: crv.keyType, x: xdata.bytes, y: ydata.bytes)
    d = ddata.bytes
    secureEnclaveKeyID = nil
  }
  
  public init(publicKeyx963Data: Data, secureEnclaveKeyID: Data) {
    key = CoseKey(crv: .p256, x963Representation: publicKeyx963Data)
    d = [] // not used
    self.secureEnclaveKeyID = secureEnclaveKeyID
  }
  
  
}

extension CoseKeyPrivate {
  public init(x: [UInt8], y: [UInt8], d: [UInt8], crv: ECCurveName = .p256) {
    self.key = CoseKey(x: x, y: y, crv: crv)
    self.d = d
    self.secureEnclaveKeyID = nil
  }
  
  /// An ANSI x9.63 representation of the private key.
  public func getx963Representation() -> Data {
    let keyData = NSMutableData(bytes: [0x04], length: [0x04].count)
    keyData.append(Data(key.x))
    keyData.append(Data(key.y))
    keyData.append(Data(d))
    return keyData as Data
  }
}

extension CoseKeyPrivate {
    // decode cbor base64
    public init?(base64: String) {
        guard let d = Data(base64Encoded: base64),
                let cbor = try? CBOR.decode([UInt8](d)) else {
            return nil
        }
        self.init(cbor: cbor)
    }
    
    // encode cbor base64
    public func base64Encoded(options: CBOROptions) -> String {
        return Data(self.encode(options: options)).base64EncodedString()
    }
}

extension CoseKeyPrivate: CBOREncodable {
    
    // Converts the CoseKeyPrivate to CBOR format
    public func toCBOR(options: CBOROptions) -> CBOR {
       
        let cbor: CBOR = [
            -1: .unsignedInt(key.crv.rawValue), // Curve name identifier
             1: .unsignedInt(key.kty.rawValue),  // Key type identifier
             -2: .byteString(key.x),             // X coordinate as byte string
             -3: .byteString(key.y),             // Y coordinate as byte string
             -4: .byteString(d) //D as byte string
        ]
        return cbor
    }
}

extension CoseKeyPrivate: CBORDecodable {
    
    // Initializes a CoseKeyPrivate from a CBOR object
    public init?(cbor obj: CBOR) {
        
        guard let coseKey = CoseKey(cbor: obj),
              let cd = obj[-4],
              case let CBOR.byteString(rd) = cd else {
            return nil
        }
        self.init(key: coseKey, d: rd)
    }
}
