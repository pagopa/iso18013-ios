//
//  SessionTranscript.swift
//  libIso18013
//
//  Created by Antonio on 17/10/24.
//

import Foundation
import SwiftCBOR

public struct SessionTranscript {
	let devEngRawData: [UInt8]?
	let eReaderRawData: [UInt8]?
	let handOver: CBOR
		
	public init(devEngRawData: [UInt8]? = nil, eReaderRawData: [UInt8]? = nil, handOver: CBOR) {
		self.devEngRawData = devEngRawData
		self.eReaderRawData = eReaderRawData
		self.handOver = handOver
	}
}

extension SessionTranscript: CBOREncodable {
	public func toCBOR(options: CBOROptions) -> CBOR {
		return .array([devEngRawData?.taggedEncoded ?? CBOR.null, eReaderRawData?.taggedEncoded ?? CBOR.null, handOver])
	}
}
