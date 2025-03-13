//
//  Data+.swift
//  libIso18013
//
//  Created by Antonio on 02/10/24.
//

import Foundation

// Extension to convert Data into an array of UInt8 (bytes)
extension Data {
    
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
