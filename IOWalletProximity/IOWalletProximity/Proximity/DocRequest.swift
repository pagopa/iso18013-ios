//
//  DocRequest.swift
//  libIso18013
//
//  Created by Antonio on 17/10/24.
//

import Foundation
import SwiftCBOR
import OrderedCollections

public struct DocRequest {
    public let itemsRequest: ItemsRequest
    public let itemsRequestRawData: [UInt8]? // items-request raw data NOT tagged
	/// Used for mdoc reader authentication
    let readerAuth: ReaderAuth?
    public let readerAuthRawCBOR: CBOR?

    enum Keys: String {
        case itemsRequest
        case readerAuth
    }
}

extension DocRequest: CBORDecodable {
    public init?(cbor: CBOR) {
        guard case let .map(m) = cbor else { return nil }
        // item-request-bytes: tagged(24, items request)
        guard case let .tagged(_, cirb) = m[Keys.itemsRequest], case let .byteString(bs) = cirb, let ir = ItemsRequest(data: bs)  else { return nil }
        itemsRequestRawData = bs; itemsRequest = ir
        if let ra = m[Keys.readerAuth] { readerAuthRawCBOR = ra; readerAuth = ReaderAuth(cbor: ra) } else { readerAuthRawCBOR = nil; readerAuth = nil }
    }
}

extension DocRequest: CBOREncodable {
	public func toCBOR(options: CBOROptions) -> CBOR {
        var m = OrderedDictionary<CBOR, CBOR>()
		if let itemsRequestRawData { m[.utf8String(Keys.itemsRequest.rawValue)] = itemsRequestRawData.taggedEncoded }
        else { m[.utf8String(Keys.itemsRequest.rawValue)] = itemsRequest.toCBOR(options: options).taggedEncoded }
        if let readerAuth { m[.utf8String(Keys.readerAuth.rawValue)] = readerAuth.toCBOR(options: options) }
        return .map(m)
    }
}

extension DocRequest {
    public var readerCertificate: Data? {
        guard let ra = readerAuth else { return nil }
        guard let cert = ra.iaca.last else { return nil }
        return Data(cert)
    }
}
