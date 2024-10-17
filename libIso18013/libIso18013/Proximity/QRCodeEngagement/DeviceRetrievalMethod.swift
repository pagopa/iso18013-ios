//
//  DeviceRetrievalMethod.swift
//  libIso18013
//
//  Created by Martina D'urso on 15/10/24.
//

import Foundation
import SwiftCBOR

/// A `DeviceRetrievalMethod` holds two mandatory values (type and version). The first element defines the type and the second element the version for the transfer method.
/// Additionally, may contain extra info for each connection.
public enum DeviceRetrievalMethod: Equatable {
    static var version: UInt64 { 1 }
    
    case qr
    case ble(isBleServer: Bool, uuid: String)
    //  case wifiaware // not supported in ios
    static let BASE_UUID_SUFFIX_SERVICE = "-0000-1000-8000-00805F9B34FB".replacingOccurrences(of: "-", with: "")
    static func getRandomBleUuid() -> String {
        let uuidFull = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        let index = uuidFull.index(uuidFull.startIndex, offsetBy: 4)
        let uuid = String(uuidFull[index...].prefix(4))
        return "0000\(uuid)\(BASE_UUID_SUFFIX_SERVICE)"
    }
}

extension DeviceRetrievalMethod: CBOREncodable {
    static func appendTypeAndVersion(_ cborArr: inout [CBOR], type: UInt64) {
        cborArr.append(.unsignedInt(type)); cborArr.append(.unsignedInt(version))
    }
	public func toCBOR(options: CBOROptions) -> CBOR {
        var cborArr = [CBOR]()
        switch self {
        case .qr:
            Self.appendTypeAndVersion(&cborArr, type: 0)
        case .ble(let isBleServer, let uuid):
            Self.appendTypeAndVersion(&cborArr, type: 2)
            let options: CBOR = [0: .boolean(isBleServer), 1: .boolean(!isBleServer), .unsignedInt(isBleServer ? 10 : 11): .byteString(uuid.byteArray)]
            cborArr.append(options)
        }
        return .array(cborArr)
    }
}

extension DeviceRetrievalMethod: CBORDecodable {
    public init?(cbor: CBOR) {
        guard case let .array(arr) = cbor, arr.count >= 2 else { return nil }
        guard case let .unsignedInt(type) = arr[0] else { return nil }
        guard case let .unsignedInt(v) = arr[1], v == Self.version else { return nil }
        switch type {
        case 0:
            self = .qr
        case 2:
            guard case let .map(options) = arr[2] else { return nil }
            if case let .boolean(b) = options[0], b, case let .byteString(bytes) = options[10] {
                self = .ble(isBleServer: b, uuid: bytes.hex)
            } else if case let .boolean(b) = options[1], b, case let .byteString(bytes) = options[11] {
                self = .ble(isBleServer: !b, uuid: bytes.hex)
            } else { return nil }
        default: return nil
        }
    }
    
}
