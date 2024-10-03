//
//  DrivingPrivileges.swift
//  libIso18013
//
//  Created by Antonio on 02/10/24.
//



import Foundation
import SwiftCBOR

public struct DrivingPrivileges: Codable {
  public let drivingPrivileges: [DrivingPrivilege]
  public subscript(i: Int) -> DrivingPrivilege { drivingPrivileges[i] }
}

extension DrivingPrivileges: CBORDecodable {
  public init?(cbor: CBOR) {
    guard case let .array(drivingPrivileges) = cbor else {
      return nil
    }
    self.drivingPrivileges = drivingPrivileges.compactMap(DrivingPrivilege.init(cbor:))
  }
}

extension DrivingPrivileges: CBOREncodable {
  public func toCBOR(options: CBOROptions) -> CBOR {
    return .array(drivingPrivileges.map { $0.toCBOR(options: options) })
  }
}
