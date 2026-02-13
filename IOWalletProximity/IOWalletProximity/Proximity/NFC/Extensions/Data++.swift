//
//  Data+.swift
//  IOWalletProximity
//
//  Created by antoniocaparello on 14/11/25.
//

import Foundation

extension Data {
    struct HexEncodingOptions: OptionSet {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return map { String(format: format, $0) }.joined()
    }

    init?(hex: String) {
        guard !hex.isEmpty else {
            return nil
        }

        guard hex.count.isMultiple(of: 2) else {
            return nil
        }

        let chars = hex.map { $0 }
        let bytes = stride(from: 0, to: chars.count, by: 2)
            .map { String(chars[$0]) + String(chars[$0 + 1]) }
            .compactMap { UInt8($0, radix: 16) }

        guard hex.count / bytes.count == 2 else { return nil }
        self.init(bytes)
    }
}

extension Data {
    func object<T>() -> T { withUnsafeBytes { $0.load(as: T.self) } }
}
