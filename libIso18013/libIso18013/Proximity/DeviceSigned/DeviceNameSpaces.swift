//
//  DeviceNameSpaces.swift
//  libIso18013
//
//  Created by Antonio on 17/10/24.
//

import SwiftCBOR

/// Device data elements per namespac
public struct DeviceNameSpaces {
	public let deviceNameSpaces: [String: DeviceSignedItems]
	public subscript(ns: String) -> DeviceSignedItems? { deviceNameSpaces[ns] }
}

extension DeviceNameSpaces: CBORDecodable {
	public init?(cbor: CBOR) {
		guard case let .map(m) = cbor else { return nil }
		let dnsPairs = m.compactMap { (k: CBOR, v: CBOR) -> (String, DeviceSignedItems)?  in
			guard case .utf8String(let ns) = k else { return nil }
			guard let dsi = DeviceSignedItems(cbor: v) else { return nil }
			return (ns,dsi)
		}
		let dns = Dictionary(dnsPairs, uniquingKeysWith: { (first, _) in first })
		deviceNameSpaces = dns
	}
}
