//
//  DeviceDocument.swift
//  libIso18013
//
//  Created by Antonio on 04/10/24.
//

public struct DeviceDocument {
  public let document: Document
  public let devicePrivateKey: CoseKeyPrivate
  
  public func coseSign(payloadData: Data, alg: Cose.VerifyAlgorithm) throws-> Cose {
    return try Cose.makeCoseSign1(payloadData: payloadData, deviceKey: devicePrivateKey, alg: alg)
  }
}
