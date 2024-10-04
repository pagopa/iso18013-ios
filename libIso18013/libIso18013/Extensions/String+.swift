//
//  String+.swift
//  libIso18013
//
//  Created by Antonio on 02/10/24.
//

import SwiftCBOR

// Extension to add CBOR encoding and date formatting utilities for String
extension String {
    
    // Computed property to encode the string as a tagged CBOR value for full dates
    var fullDateEncoded: CBOR {
        // Tag the string with the custom tag (1004) and encode it as a CBOR utf8String
        return CBOR.tagged(CBOR.Tag(rawValue: 1004), .utf8String(self))
    }
    
    // Function to format the string as a POSIX date (either ISO format or MM/DD/YYYY format)
    // - Parameter useIsoFormat: Boolean to indicate whether to use ISO format (default is true)
    // - Returns: The formatted date string or an empty string if the format is invalid
    public func toPosixDate(useIsoFormat: Bool = true) -> String {
        // Split the string at the "T" separator and take the first part (the date)
        guard let dateString = self.split(separator: "T").first else { return "" }
        
        // Return the date in ISO format if specified
        if useIsoFormat {
            return String(dateString)
        }
        
        // Split the date string into components (year, month, day)
        let dateComponents = dateString.split(separator: "-")
        guard dateComponents.count >= 3 else { return "" }
        
        // Return the date in MM/DD/YYYY format
        return "\(dateComponents[1])/\(dateComponents[2])/\(dateComponents[0])"
    }
}
