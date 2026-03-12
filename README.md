# ISO 18013 iOS Library Documentation

## Overview

The ISO18013 library is a comprehensive Swift framework for implementing ISO 18013-5 (Mobile Driver's License - mDOC) functionality on iOS devices. It enables wallet applications to act as credential holders, supporting proximity-based data presentation through QR codes, NFC, and BLE technologies.

## Core Architecture

### Main Components

The library is built around a few key components working together to manage the mDOC presentation flow:

#### 1. **ISO18013 Singleton**
The main entry point for the library. Manages the entire lifecycle of engagement and data transfer.

```swift
ISO18013.shared.start(
    trustedCertificates,
    engagementModes: [.qrCode],
    retrivalMethods: [.ble],
    delegate: self,
    isNfcLateEngagement: false
)
```

See [ISO18013.swift](IOWalletProximity/IOWalletProximity/ISO18013.swift#L1) for implementation and [ISO18013View.swift](IOWalletProximityExample/IOWalletProximityExample/View/ISO18013View.swift#L190) for usage in code.

#### 2. **Event-Driven Architecture**

The library uses an event-based system to communicate state changes to the application:

**ISO18013Event** - Represents different states during the mDOC presentation:
- `.qrCode(String)` - QR code for engagement is ready
- `.bleConnecting` - Establishing BLE connection with verifier
- `.bleConnected` - BLE connection established
- `.nfcStarted` - NFC Host Card Emulation started
- `.nfcStopped` - NFC HCE stopped
- `.nfcEngagementStarted` - NFC engagement phase begun
- `.nfcEngagementDone` - NFC engagement completed
- `.dataTransferStarted(ISO18013DataTransferArgs)` - Verifier requesting document data
- `.dataTransferStopped` - Data transfer complete
- `.error(Error)` - An error occurred

#### 3. **Engagement Modes**

Defines how the holder and verifier establish initial contact:

```swift
public enum ISO18013EngagementMode : Sendable {
    case qrCode  // QR code engagement
    case nfc     // NFC Host Card Emulation engagement
}
```

See [ISO18013View.swift](IOWalletProximityExample/IOWalletProximityExample/View/ISO18013View.swift#L12) for configuration toggles demonstrating both modes.

#### 4. **Data Transfer Modes**

Specifies the communication method after engagement:

```swift
public enum ISO18013DataTransferMode : Sendable {
    case ble  // Bluetooth Low Energy
    case nfc  // NFC
}
```

## Initialization & Configuration

### Basic Startup

```swift
ISO18013.shared.start(
    trustedCertificates: [[Data]]?,
    engagementModes: [ISO18013EngagementMode],
    retrivalMethods: [ISO18013DataTransferMode],
    delegate: ISO18013Delegate,
    isNfcLateEngagement: Bool
)
```

**Parameters:**
- `trustedCertificates`: Optional list of trusted certificates to verify reader/verifier validity (X.509 format)
- `engagementModes`: How initial contact is established (QR, NFC)
- `retrivalMethods`: How data is transferred (BLE, NFC)
- `delegate`: Handler implementing `ISO18013Delegate` protocol to receive events
- `isNfcLateEngagement`: Allows NFC initialization after engagement phase starts

See [ISO18013View.swift](IOWalletProximityExample/IOWalletProximityExample/View/ISO18013View.swift#L164) for complete startup example with certificate configuration.

### NFC Session Management

```
NFC Host Card Emulation is supported only on iOS 17.4+
```

The library enforces NFC session time constraints:

```swift
public static let nfcHLESessionTimeRemaining: TimeInterval = 15
public static let nfcHLESessionCoolDownTimeRemaining: TimeInterval = 15
```

- **Session Duration**: 15 seconds for active NFC HCE
- **Cool-down Period**: 15 seconds mandatory wait before re-establishing NFC

See [ISO18013View.swift](IOWalletProximityExample/IOWalletProximityExample/View/ISO18013View.swift#L65) for timer management implementation.

## Event Handling

### Delegate Protocol

Implement `ISO18013Delegate` to handle library events:

```swift
public protocol ISO18013Delegate {
    func onEvent(event: ISO18013Event)
}
```

See [ISO18013View.swift](IOWalletProximityExample/IOWalletProximityExample/View/ISO18013View.swift#L409) for complete delegate implementation showing all event cases.

### Event Handling Example

```swift
func onEvent(event: ISO18013Event) {
    switch(event) {
    case .qrCode(let qrCode):
        // Display QR code for engagement
        displayQRCode(qrCode)
    case .bleConnecting:
        // Show connecting indicator
        showLoadingState()
    case .dataTransferStarted(let args):
        // Verifier requesting data
        handleDataRequest(args)
    case .error(let error):
        // Handle error appropriately
        showError(error)
    default:
        break
    }
}
```

## Data Transfer Flow

### Request Handling

When a verifier requests document data, the library emits `.dataTransferStarted` with:

```swift
public struct ISO18013DataTransferArgs: Sendable {
    public let engagementMethod: ISO18013EngagementMode
    public let retrivalMethod: ISO18013DataTransferMode
    public let request: [
        (docType: String,
         nameSpaces: [String: [String: Bool]],
         isAuthenticated: Bool)
    ]?
}
```

The `request` structure indicates which document types and data fields are being requested.

See [ISO18013View.swift](IOWalletProximityExample/IOWalletProximityExample/View/ISO18013View.swift#L361) for parsing request data.

### Response Generation

#### Generate Device Response

```swift
let deviceResponse = try ISO18013.shared.generateDeviceResponse(
    items: [String: [String: [String: Bool]]]?,
    documents: [ProximityDocument]?,
    sessionTranscript: [UInt8]?
) -> throws [UInt8]
```

Generates CBOR-encoded response with selected document fields.

#### JSON Alternative

```swift
let deviceResponse = try ISO18013.shared.generateDeviceResponseFromJson(
    items: String?,
    documents: [ProximityDocument]?,
    sessionTranscript: [UInt8]?
) -> throws [UInt8]
```

Same as above but accepts JSON string for `items` parameter.

#### Send Response

```swift
try ISO18013.shared.dataPresentation(deviceResponse)
```

See [ISO18013View.swift](IOWalletProximityExample/IOWalletProximityExample/View/ISO18013View.swift#L365) for complete response handling.

### Error Response

```swift
try ISO18013.shared.errorPresentation(SessionDataStatus)
```

Sends error response instead of data when request cannot be fulfilled.

## Advanced Features

### Late NFC Initialization

For scenarios where NFC should only be activated after engagement begins:

```swift
// Start with isNfcLateEngagement: true
ISO18013.shared.start(..., isNfcLateEngagement: true)

// Later, after engagement phase starts:
try ISO18013.shared.lateNfcInitialization()
```

Useful for conserving battery or controlling when NFC becomes available.

See [ISO18013View.swift](IOWalletProximityExample/IOWalletProximityExample/View/ISO18013View.swift#L249) for UI implementation.

### NFC HCE Custom Message

Set custom message displayed in native NFC interface:

```swift
@available(iOS 17.4, *)
ISO18013.shared.setNfcHceMessage(message: String)
```

See [ISO18013View.swift](IOWalletProximityExample/IOWalletProximityExample/View/ISO18013View.swift#L415) for usage.

### OID4VP Integration

Support for ISO 18013-7 OAuth-based flow:

```swift
public func generateOID4VPSessionTranscriptCBOR(
    clientId: String,
    responseUri: String,
    authorizationRequestNonce: String,
    mdocGeneratedNonce: String
) -> [UInt8]
```

Generates CBOR-encoded session transcript for OpenID4VP authorization flows.

## Utility Methods

### Check BLE Status

```swift
let bleEnabled = ISO18013.shared.isBleEnabled() -> Bool
```

Verify if Bluetooth is enabled before offering BLE engagement.

### Shutdown

```swift
ISO18013.shared.stop()
```

Stops all engagement mechanisms (BLE manager, NFC HCE) and closes connections.

## Configuration Scenarios

### Scenario 1: QR Code + BLE

Simplest flow for platforms without NFC:

```swift
ISO18013.shared.start(
    engagementModes: [.qrCode],
    retrivalMethods: [.ble],
    delegate: self,
    isNfcLateEngagement: false
)
```

See [ISO18013View.swift](IOWalletProximityExample/IOWalletProximityExample/View/ISO18013View.swift#L178) for preset button.

### Scenario 2: QR Code + NFC Data Transfer

QR for engagement, but data over NFC:

```swift
ISO18013.shared.start(
    engagementModes: [.qrCode],
    retrivalMethods: [.nfc],
    delegate: self,
    isNfcLateEngagement: false
)
```

### Scenario 3: NFC with Late Initialization

NFC for both engagement and data, but enable NFC only on demand:

```swift
ISO18013.shared.start(
    engagementModes: [.nfc],
    retrivalMethods: [.nfc],
    delegate: self,
    isNfcLateEngagement: true
)
```

Later, activate NFC when needed:

```swift
try ISO18013.shared.lateNfcInitialization()
```

## Error Handling

The library throws errors as events (`.error(Error)`) and through exceptions:

Common error scenarios:
- `ProximityError.nfcAlreadyStarted` - NFC already active
- `ProximityError.nfcCooldownNotExpired` - 15-second cool-down not elapsed
- `ProximityError.nfcFailedToStart` - NFC initialization failed
- CBOR encoding/decoding errors during response generation
- Certificate verification failures

See [ISO18013View.swift](IOWalletProximityExample/IOWalletProximityExample/View/ISO18013View.swift#L420) for error handling in the UI layer.

## Data Structure

### Document Request

When data is requested, the structure is:

```
docType: String (e.g., "org.iso.18013.5.1.mDL")
nameSpaces: Dictionary
    key: namespace (e.g., "org.iso.18013.5.1")
    value: Dictionary
        key: element identifier (e.g., "family_name", "birth_date")
        value: Boolean (whether field is requested)
isAuthenticated: Boolean (whether reader is authenticated)
```

### Document Response

Response structure mirrors request but with actual data values:

```swift
[String: [String: [String: Any]]]
```

Encoded as CBOR for transmission.

## Integration Checklist

- [ ] Obtain trusted certificates for reader verification
- [ ] Choose engagement mode(s) and data transfer mode(s)
- [ ] Implement `ISO18013Delegate` protocol
- [ ] Load documents (with issuerSigned and deviceKey data)
- [ ] Call `ISO18013.shared.start()` with configuration
- [ ] Handle events in delegate methods
- [ ] Generate and send `dataPresentation` responses
- [ ] Call `ISO18013.shared.stop()` for cleanup
- [ ] Test with real verifier applications

See [ISO18013View.swift](IOWalletProximityExample/IOWalletProximityExample/View/ISO18013View.swift) for complete integration example.

## Best Practices

1. **Certificate Management**: Keep trusted certificates updated and validate against revocation lists
2. **NFC Session Timing**: Respect the 15-second session and 15-second cool-down windows
3. **Error Recovery**: Implement retry logic for transient failures like NFC cool-down
4. **User Feedback**: Show clear UI indicators for different engagement modes (QR scanner vs. NFC)
5. **Document Validation**: Verify document authenticity before responding to requests
6. **User Consent**: Always get explicit user approval before sharing document data
7. **Memory Management**: Properly stop all engagement mechanisms when done

## References

- [ISO 18013-5 Standard](https://www.iso.org/standard/69084.html) - mDOC specification
- [ISO 18013-7](https://www.iso.org/standard/80601.html) - OID4VP integration
- Main Implementation: [ISO18013.swift](IOWalletProximity/IOWalletProximity/ISO18013.swift)
- Example Usage: [ISO18013View.swift](IOWalletProximityExample/IOWalletProximityExample/View/ISO18013View.swift)
