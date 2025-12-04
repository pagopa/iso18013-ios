//
//  Array<UInt8>+.swift
//  IOWalletProximity
//
//  Created by antoniocaparello on 14/11/25.
//

import Foundation

extension Array<UInt8> {
    init?(hex: String) {
        guard let data = Data(hex: hex) else {
            return nil
        }
        self.init(data)
    }
    
    var hexEncodedString: String {
        return Data(self).hexEncodedString()
    }
    
    var hexDump: String {
        return HexDump.hexDumpStringForBytes(bytes: self)
    }
    
}
