# iso18013-ios

The library offers a specific set of functions to handle BLE proximity as specified by iso-18013

### ISO18013-5 Proximity

#### Proximity.shared.proximityHandler

```swift
//  In order to listen for proximity events set this handler

public enum ProximityEvents {
    case onBleStart
    case onBleStop
    case onDocumentRequestReceived(request:  (request: [(docType: String, nameSpaces: [String: [String: Bool]])]?, isAuthenticated: Bool)?)
    case onDocumentPresentationCompleted
    case onError(error: Error)
    case onLoading
}

 Proximity.shared.proximityHandler = {
    event in
    print(event)
}
```


#### Proximity.shared.start

```swift
//  Initialize the BLE manager, set the necessary listeners. Start the BLE and generate the QRCode string
//  - Parameters:
//      - trustedCertificates: list of trusted certificates to verify reader validity
//  - Returns: A string containing the DeviceEngagement data necessary to start the verification process

let qrCode = Proximity.shared.start()
```

#### Proximity.shared.stop

```swift
//  Stops the BLE manager and closes connections.

Proximity.shared.stop()
```


#### Proximity.shared.generateDeviceResponseFromJsonWithSecKey
```swift
//  Generate response to request for data from the reader.
//  - Parameters:
//      - allowed: User has allowed the verification process
//      - items: json of map of [documentType: [nameSpace: [elementIdentifier: allowed]]] as String
//      - documents: Map of documents. Key is docType, first item is issuerSigned as cbor and second item is SecKey
//      - sessionTranscript: optional CBOR encoded session transcript
public func generateDeviceResponseFromJsonWithSecKey(
    allowed: Bool,
    items: String?,
    documents: [String: ([UInt8], SecKey)]?,
    sessionTranscript: [UInt8]?
) -> [UInt8]?
```

#### Proximity.shared.generateDeviceResponseFromDataWithSecKey
```swift
//  Generate response to request for data from the reader.
//  - Parameters:
//      - allowed: User has allowed the verification process
//      - items: json of map of [documentType: [nameSpace: [elementIdentifier: allowed]]]
//      - documents: Map of documents. Key is docType, first item is issuerSigned as cbor and second item is SecKey
//      - sessionTranscript: optional CBOR encoded session transcript
public func generateDeviceResponseFromDataWithSecKey(
    allowed: Bool,
    items: [String: [String: [String: Bool]]]?,
    documents: [String: ([UInt8], SecKey)]?,
    sessionTranscript: [UInt8]?
) -> [UInt8]?
```


#### Proximity.shared.generateDeviceResponseFromData
```swift
//  Generate response to request for data from the reader.
//  - Parameters:
//      - allowed: User has allowed the verification process
//      - items: Map of [documentType: [nameSpace: [elementIdentifier: allowed]]]
//      - documents: Map of documents. Key is docType, first item is issuerSigned as cbor and second item is CoseKeyPrivate encoded
//      - sessionTranscript: optional CBOR encoded session transcript

let items: [String: [String: [String: Bool]]] = [:]

let documents = LibIso18013DAOKeyChain().getAllDocuments(state: .issued).compactMap({
    document in
    if let documentData = document.issuerSigned {
        return (document.docType, documentData, document.deviceKeyData)
    }
    return nil
})
                    
var documentMap: [String: ([UInt8], [UInt8])] = [:]

documents.forEach({
    document in
    documentMap[document.0] = (document.1, document.2)
})
                    
let response = Proximity.shared.generateDeviceResponse(allowed: allowed, items: items, documents: documentMap)
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

//Map of [documentType : (issuerSigned, deviceKey)]
var documentMap: [String: ([UInt8], SecKey)] = [:]

let deviceResponse = Proximity.shared.generateDeviceResponseFromDataWithSecKey(
    allowed: true,
    items: items, 
    documents: documentMap,
    sessionTranscript: sessionTranscript
)

//send deviceResponse to OpenID4VP backend

```