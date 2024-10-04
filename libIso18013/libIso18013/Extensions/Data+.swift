//
//  Data+.swift
//  libIso18013
//
//  Created by Antonio on 02/10/24.
//

// Extension to convert Data into an array of UInt8 (bytes)
extension Data {
    
    public var bytes: Array<UInt8> {
        return Array(self)
    }
}
