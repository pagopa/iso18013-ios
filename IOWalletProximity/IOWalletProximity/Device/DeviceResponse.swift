//
//  DeviceResponse.swift
//  libIso18013
//
//  Created by Martina D'urso on 04/10/24.
//

import Foundation
internal import SwiftCBOR
internal import OrderedCollections

struct DeviceResponse {
    
    public let version: String
    public static let defaultVersion = "1.0" // The default version if none is specified.
    public let documents: [Document]?
    public let documentErrors: [DocumentError]?
    // Documents in formats other than mdoc, e.g. SD-JWT VC (ISO/IEC 18013-5 second edition)
    public let otherDocuments: [ProximityOtherDocument]?
    public let status: UInt64
    
    // The version required by the ISO/IEC 18013-5 second edition structures, e.g. otherDocuments
    static let secondEditionVersion = "1.1"
    
    enum Keys: String {
        case version
        case documents
        case documentErrors
        case otherDocuments
        case status
    }
    
    // Initializer for creating a DeviceResponse instance.
    // - Parameters:
    //   - version: Optional version of the response. Defaults to `defaultVersion` if nil.
    //   - documents: Optional array of returned documents.
    //   - documentErrors: Optional array of document errors.
    //   - otherDocuments: Optional array of documents in other formats. When present, the version defaults to 1.1.
    //   - status: The status code of the response.
    public init(
        version: String? = nil,
        documents: [Document]? = nil,
        documentErrors: [DocumentError]? = nil,
        otherDocuments: [ProximityOtherDocument]? = nil,
        status: UInt64
    ) {
        self.version = version ?? (otherDocuments == nil ? Self.defaultVersion : Self.secondEditionVersion)
        self.documents = documents
        self.documentErrors = documentErrors
        self.otherDocuments = otherDocuments
        self.status = status
    }
}

// Extension to make DeviceResponse conform to CBORDecodable protocol
extension DeviceResponse: CBORDecodable {
    
    // Initializes a DeviceResponse instance from a CBOR object
    // - Parameter cbor: A CBOR object that contains the data for the response
    public init?(cbor: CBOR) throws {
        
        // Ensure the CBOR object is a map (key-value structure)
        guard case .map(let cd) = cbor else { return nil }
        
        // Extract the version string from the CBOR map
        guard case .utf8String(let v) = cd[Keys.version] else { return nil }
        version = v
        
        // Extract the documents array, if present, and decode each document
        if case let .array(ar) = cd[Keys.documents] {
            let ds = try ar.compactMap { try Document(cbor: $0) } // Map the CBOR array to Document instances
            documents = ds.count > 0 ? ds : nil           // Assign documents if there are any
        } else {
            documents = nil
        }
        
        // Extract the document errors array, if present, and decode each document error
        if case let .array(are) = cd[Keys.documentErrors] {
            let de = try are.compactMap { try DocumentError(cbor: $0) } // Map the CBOR array to DocumentError instances
            documentErrors = de.count > 0 ? de : nil            // Assign documentErrors if there are any
        } else {
            documentErrors = nil
        }
        
        // Extract the documents in other formats, if present
        if case let .array(aro) = cd[Keys.otherDocuments] {
            let od = aro.compactMap { item -> ProximityOtherDocument? in
                guard case let .utf8String(docFormat) = item[.utf8String(ProximityOtherDocument.Keys.docFormat.rawValue)],
                      case let .byteString(data) = item[.utf8String(ProximityOtherDocument.Keys.data.rawValue)] else { return nil }
                return ProximityOtherDocument(docFormat: docFormat, data: data)
            }
            otherDocuments = od.count > 0 ? od : nil
        } else {
            otherDocuments = nil
        }
        
        // Extract the status value from the CBOR map
        guard case .unsignedInt(let st) = cd[Keys.status] else { return nil }
        status = st
    }
}


// Extension to make DeviceResponse conform to CBOREncodable protocol
extension DeviceResponse: CBOREncodable {
    
    // Encodes the DeviceResponse instance into a CBOR object
    // - Parameter options: Options for encoding CBOR
    // - Returns: A CBOR representation of the DeviceResponse
    public func toCBOR(options: CBOROptions) -> CBOR {
        var cbor = OrderedDictionary<CBOR, CBOR>()
        
        // Add the version to the CBOR map
        cbor[.utf8String(Keys.version.rawValue)] = .utf8String(version)
        
        // Encode documents if they exist
        if let ds = documents {
            cbor[.utf8String(Keys.documents.rawValue)] = ds.toCBOR(options: options)
        }
        
        // Encode document errors if they exist
        if let de = documentErrors {
            cbor[.utf8String(Keys.documentErrors.rawValue)] = .array(de.map { $0.toCBOR(options: options) })
        }
        
        // Encode documents in other formats if they exist
        if let od = otherDocuments {
            cbor[.utf8String(Keys.otherDocuments.rawValue)] = .array(od.map { $0.toCBOR(options: options) })
        }
        
        // Add the status to the CBOR map
        cbor[.utf8String(Keys.status.rawValue)] = .unsignedInt(status)
        
        // Return the CBOR map
        return .map(cbor)
    }
}
