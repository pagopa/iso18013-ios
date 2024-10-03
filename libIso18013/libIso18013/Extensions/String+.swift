//
//  String+.swift
//  libIso18013
//
//  Created by Antonio on 02/10/24.
//

import SwiftCBOR

extension String {
  var fullDateEncoded: CBOR {
    CBOR.tagged(CBOR.Tag(rawValue: 1004), .utf8String(self))
  }
  
  public func toPosixDate(useIsoFormat: Bool = true) -> String {
    guard let ds = self.split(separator: "T").first else { return "" }
    if useIsoFormat { return String(ds)}
    let dc = ds.split(separator: "-")
    guard dc.count >= 3 else { return "" }
    return "\(dc[1])/\(dc[2])/\(dc[0])"
  }
}
