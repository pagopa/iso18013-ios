# IOWalletProximity - ISO 18013 iOS Library

## Overview

IOWalletProximity is an iOS library that implements the ISO 18013 standard for mobile driving licenses (mDL) and digital identity documents. This library is part of the Italian Digital Identity Wallet implementation, providing native iOS support for secure document verification and presentation through proximity protocols.

## Features

- **ISO 18013-5 Compliance**: Full implementation of the ISO 18013-5 standard for mobile driving licenses
- **Secure Document Transfer**: Secure transfer of identity documents via BLE (Bluetooth Low Energy)
- **QR Code Engagement**: Generation and processing of QR codes for establishing secure connections
- **Selective Disclosure**: Support for selective disclosure of personal data attributes
- **CBOR Encoding**: Compact Binary Object Representation for efficient data exchange
- **Document Authentication**: Cryptographic verification of document authenticity
- **OID4VP Support**: Implementation of OpenID for Verifiable Presentations (ISO 18013-7)

## Requirements

- iOS 13.0+
- Swift 5.0+
- Xcode 12.0+

## Installation

### CocoaPods

Add the following to your `Podfile`:

```ruby
pod 'IOWalletProximity', '~> 0.0.6'
```

Then run:

```bash
pod install
```

## Usage

### Initialize the Proximity Service

```swift
import IOWalletProximity

// Start the proximity service
try Proximity.shared.start()

let qrCode = try Proximity.shared.getQrCode()

print(qrCode)

//  Stops the BLE manager and closes connections.
Proximity.shared.stop()


// Listen for proximity events
Proximity.shared.proximityHandler = { event in
    switch event {
        //The device is done sending documents
        case onDocumentPresentationCompleted:
        break
    
        //The device is connecting to the verifier app
        case onDeviceConnecting:
        break
    
        //The device has connected to the verifier app
        case onDeviceConnected:
        break
    
        //The device has received a new request from the verifier app
        case onDocumentRequestReceived(request: [
            (docType: String,
            nameSpaces: [String: [String: Bool]],
            isAuthenticated: Bool)
        ]?):
        break
    
        //The device has received the termination flag from the verifier app
        case onDeviceDisconnected:
        break
    
        //An error occurred
        case onError(error: Error):
        break
    }
}
```

#### ProximityDocument

```swift
//  ProximityDocument is a class to store docType, issuerSigned and deviceKey.
//  It can be initialized in various ways. The difference is the source of the deviceKey

//  This constructor allows to initialize the object with a COSEKey CBOR encoded deviceKey
public convenience init?(docType: String, issuerSigned: [UInt8], deviceKeyRaw: [UInt8])

//  This constructor allows to initialize the object with a SecKey deviceKey
public convenience init?(docType: String, issuerSigned: [UInt8], deviceKeySecKey: SecKey)

//  This constructor allows to initialize the object with a String representing the SecKey in the keychain
public convenience init?(docType: String, issuerSigned: [UInt8], deviceKeyTag: String)
```

#### Proximity.shared.proximityHandler

```swift
//  In order to listen for proximity events set this handler


public enum ProximityEvents {
    //The device is done sending documents
    case onDocumentPresentationCompleted
    
    //The device is connecting to the verifier app
    case onDeviceConnecting
    
    //The device has connected to the verifier app
    case onDeviceConnected
    
    //The device has received a new request from the verifier app
    case onDocumentRequestReceived(request: [
        (docType: String,
         nameSpaces: [String: [String: Bool]],
         isAuthenticated: Bool)
    ]?)
    
    //The device has received the termination flag from the verifier app
    case onDeviceDisconnected
    
    //An error occurred
    case onError(error: Error)
    
}

 Proximity.shared.proximityHandler = {
    event in
    print(event)
}
```

#### Proximity.shared.generateDeviceResponseFromJson

```swift
/**
 * Generate DeviceResponse to request for data from the reader.
 *
 * - Parameters:
 *   - allowed: User has allowed the verification process
 *   - items: json of map of [documentType: [nameSpace: [elementIdentifier: allowed]]] as String
 *   - documents: List of documents.
 *   - sessionTranscript: optional CBOR encoded session transcript
 *
 * - Returns: CBOR-encoded DeviceResponse object as value
 */
public func generateDeviceResponseFromJson(
    allowed: Bool,
    items: String?,
    documents: [ProximityDocument]?,
    sessionTranscript: [UInt8]?
) throws -> [UInt8]
```

#### Proximity.shared.generateDeviceResponse

```swift
/**
 * Generate DeviceResponse to request for data from the reader.
 *
 * - Parameters:
 *   - allowed: User has allowed the verification process
 *   - items: json of map of [documentType: [nameSpace: [elementIdentifier: allowed]]]
 *   - documents: List of documents.
 *   - sessionTranscript: optional CBOR encoded session transcript
 *
 * - Returns: CBOR-encoded DeviceResponse object as value
 */
public func generateDeviceResponse(
    allowed: Bool,
    items: [String: [String: [String: Bool]]]?,
    documents: [ProximityDocument]?,
    sessionTranscript: [UInt8]?
) throws -> [UInt8]
```

```swift
let items: [String: [String: [String: Bool]]] = [:]

let documents = LibIso18013DAOKeyChain()
    .getAllDocuments(state: .issued)
    .compactMap({
        if let issuerSigned = $0.issuerSigned {
            return ProximityDocument(
                docType: $0.docType,
                issuerSigned: issuerSigned,
                deviceKeyRaw: $0.deviceKeyData
            )
        }
        return nil
    })


let deviceResponseStatus = Proximity.shared
    .generateDeviceResponse(
        allowed: allowed,
        items: items,
        documents: documents,
        sessionTranscript: nil
        )

switch(deviceResponseStatus) {
    case .success(let deviceResponse):
        //use deviceResponse
        print(deviceResponse)
    default:
        print(deviceResponseStatus)
        //generateDeviceResponse failed for some reasons
}
```

#### Proximity.shared.dataPresentation

```swift
//  Responds to a request for data from the reader.
//  - Parameters:
//      - allowed: User has allowed the verification process
//      - deviceResponse: Device Response cbor-encoded (result of Proximity.shared.generateDeviceResponse)

let deviceResponse: [UInt8] = /*result of generateDeviceResponse*/

Proximity.shared.dataPresentation(allowed: allowed, deviceResponse)
```

#### ProximityError

```swift

//  Possible response errors of various methods

public enum ProximityError {
    case nullObject(objectName: String)
    case decodingFailed(objectName: String)
    case error(error: Error)
}
```

### ISO18013-7 Remote Presentation (OpenID4VP)

#### Proximity.shared.generateOID4VPSessionTranscriptCBOR

```swift
/**
    * Generate session transcript with OID4VPHandover
    * This method is used for ISO 18013-7 OID4VP flow.
    *
    * - Parameters:
    *   - clientId: Authorization Request 'client_id'
    *   - responseUri: Authorization Request 'response_uri'
    *   - authorizationRequestNonce: Authorization Request 'nonce'
    *   - mdocGeneratedNonce: cryptographically random number with sufficient entropy
    *
    * - Returns: A CBOR-encoded SessionTranscript object
*/
public func generateOID4VPSessionTranscriptCBOR(
    clientId: String,
    responseUri: String,
    authorizationRequestNonce: String,
    mdocGeneratedNonce: String
) -> [UInt8]
```

#### Example

```swift
let mdocGeneratedNonce: String = /*generate cryptographically random number with sufficient entropy*/

let openId4VpRequest = /*retrive openId4VpRequest using mdocGeneratedNonce*/

let sessionTranscript = Proximity.shared.generateOID4VPSessionTranscriptCBOR(
    clientId: openId4VpRequest.client_id,
    responseUri: openId4VpRequest.response_uri,
    authorizationRequestNonce: openId4VpRequest.nonce,
    mdocGeneratedNonce: mdocGeneratedNonce
)
//Map of [documentType: [nameSpace: [elementIdentifier: allowed]]]
let items: [String: [String: [String: Bool]]] = [:] //items should contain all the items received in the openId4VpRequest.

//List of ProximityDocument
var documents: [ProximityDocument] = []

let deviceResponseStatus = Proximity.shared.generateDeviceResponse(
    allowed: true,
    items: items,
    documents: documents,
    sessionTranscript: sessionTranscript
)

switch(deviceResponseStatus) {
    case .success(let deviceResponse):
        //send deviceResponse to OpenID4VP backend
        print(deviceResponse)
    default:
        print(deviceResponseStatus)
        //generateDeviceResponse failed for some reasons
}

```

## Running Tests

You can run the IOWalletProximity unit tests following these steps:

### From Xcode

1. Open the project `IOWalletProximity/IOWalletProximity.xcodeproj` in Xcode
2. Select the `IOWalletProximity` scheme
3. Press ⌘+U or go to Product > Test

### From Terminal

You can run the tests from the command line with the following command:

```bash
xcodebuild test \
  -project IOWalletProximity/IOWalletProximity.xcodeproj \
  -scheme IOWalletProximity \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  -enableCodeCoverage YES
```

To generate a test results bundle, you can add the `-resultBundlePath` parameter:

```bash
xcodebuild test \
  -project IOWalletProximity/IOWalletProximity.xcodeproj \
  -scheme IOWalletProximity \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  -resultBundlePath TestResults.xcresult \
  -enableCodeCoverage YES
```

## Example Application

The repository includes an example application (`IOWalletProximityExample`) demonstrating how to use the library to:

- Create and store digital documents
- Present documents via BLE
- Generate QR codes for verification
- Handle document requests with user consent

In order to run the example application we suggesting using [bundler](https://bundler.io/) to manage ruby dependencies and [rbenv](https://github.com/rbenv/rbenv) to manage ruby versions:

```bash
gem install bundler
bundle install
cd IOWalletProximityExample
bundler exec pod update
# Open IOWalletProximityExample\IOWalletProximityExample.xcworkspace using Xcode.
```

## Architecture

The library consists of several key components:

- **Proximity**: Main interface for handling document presentation
- **DeviceEngagement**: Handles the connection establishment process
- **SessionEncryption**: Manages secure encrypted sessions
- **Document**: Represents identity documents with issuer-signed data
- **MdocBleServer**: Manages BLE server for secure proximity connections
