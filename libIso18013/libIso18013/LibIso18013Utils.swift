//
//  LibIso18013Utils.swift
//  libIso18013
//
//  Created by Antonio on 01/10/24.
//
import Foundation

public protocol LibIso18013UtilsProtocol {
  func decodeDocument(base64Encoded: String) -> Document?
  func decodeDocument(data: Data) -> Document?
}

public class LibIso18013Utils : LibIso18013UtilsProtocol {
  public func decodeDocument(base64Encoded: String) -> Document? {
    guard let documentData = Data(base64Encoded: base64Encoded) else {
      return nil
    }
    return decodeDocument(data: documentData)
  }
  
  public func decodeDocument(data: Data) -> Document? {
    return Document(data: [UInt8](data))
  }
}

