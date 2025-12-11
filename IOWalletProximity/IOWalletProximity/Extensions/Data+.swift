//
//  Data+.swift
//  libIso18013
//
//  Created by Antonio on 02/10/24.
//

import Foundation

// Extension to convert Data into an array of UInt8 (bytes)
extension Data {

    /// Initializes Data from a base64-url encoded string.
    ///
    /// https://tools.ietf.org/html/rfc4648#page-7
    ///
    /// - parameter string: The base64-url encoded string.
    /// - returns: Data if decoding succeeds, nil otherwise.
    public init?(base64URLEncoded string: String) {
        let base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let paddedLength = (4 - base64.count % 4) % 4
        let padded = base64 + String(repeating: "=", count: paddedLength)
        self.init(base64Encoded: padded)
    }
    
    public var bytes: Array<UInt8> {
        return Array(self)
    }
    
    /// Encodes data to a base64-url encoded string.
    ///
    /// https://tools.ietf.org/html/rfc4648#page-7
    ///
    /// - parameter options: The options to use for the encoding. Default value is `[]`.
    /// - returns: The base64-url encoded string.
    public func base64URLEncodedString(options: Data.Base64EncodingOptions = []) -> String {
        return base64EncodedString(options: options).base64URLEscaped()
    }
    
    public func decodeJSON<T: Decodable>(type: T.Type = T.self) -> T? {
        let decoder = JSONDecoder()
        guard let response = try? decoder.decode(type.self, from: self) else { return nil }
        return response
    }
}
