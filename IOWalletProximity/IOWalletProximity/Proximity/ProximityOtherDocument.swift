//
//  ProximityOtherDocument.swift
//  IOWalletProximity
//


import Foundation
internal import SwiftCBOR
internal import OrderedCollections

//  ProximityOtherDocument is a document in a format other than mdoc, e.g. SD-JWT VC,
//  returned in the otherDocuments of the DeviceResponse defined by the ISO/IEC 18013-5 second edition.
//  The document is already presented by the caller: it is added to the response as it is.
public struct ProximityOtherDocument {
    //  The format of the document, e.g. dc+sd-jwt
    public let docFormat: String
    //  The presented document, compressed with zlib (RFC 1950)
    public let data: [UInt8]

    enum Keys: String {
        case docFormat
        case data
    }

    public init(docFormat: String, data: [UInt8]) {
        self.docFormat = docFormat
        self.data = data
    }
}

// Not a CBOREncodable conformance, since the type is public and SwiftCBOR is imported internally
extension ProximityOtherDocument {
    func toCBOR(options: CBOROptions) -> CBOR {
        var m = OrderedDictionary<CBOR, CBOR>()
        m[.utf8String(Keys.docFormat.rawValue)] = .utf8String(docFormat)
        m[.utf8String(Keys.data.rawValue)] = .byteString(data)
        return .map(m)
    }
}
