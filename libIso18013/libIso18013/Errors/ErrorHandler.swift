//
//  ErrorHandler.swift
//  libIso18013
//
//  Created by Martina D'urso on 08/10/24.
//

import Foundation

// Error handling class to centralize error messages
public enum ErrorHandler: Error {
    public var localizedDescription: String {
        switch self {
            case .invalidBase64EncodingError:
                return "Invalid base64 encoding"
            case .documentDecodingFailedError:
                return "Document decoding failed"
            case .invalidDeviceKeyError:
                return "Invalid device key"
                
            case .secureEnclaveNotSupported:
                return "Secure Enclave not supported on this device"
            case .secureEnclaveNotSupportedAlgorithm(let algorithm):
                return "\(algorithm) not supported with Secure Enclave"
            case .documentWithIdentifierNotFound:
                return "No stored document found with this identifier"
            case .documentMustBeUnsigned:
                return "Document must be unsigned"
        }
    }
    case invalidBase64EncodingError
    case documentDecodingFailedError
    case invalidDeviceKeyError
    
    case secureEnclaveNotSupported
    case secureEnclaveNotSupportedAlgorithm(algorithm: ECCurveName)
    //DAO
    case documentWithIdentifierNotFound
    case documentMustBeUnsigned
    
}
