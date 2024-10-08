//
//  ErrorHandler.swift
//  libIso18013
//
//  Created by Martina D'urso on 08/10/24.
//

import Foundation

// Error handling class to centralize error messages
enum ErrorHandler: Error {
    var localizedDescription: String {
        switch self {
            case .invalidBase64EncodingError:
                return "Invalid base64 encoding"
            case .documentDecodingFailedError:
                return "Document decoding failed"
        }
    }
    case invalidBase64EncodingError
    case documentDecodingFailedError
}
