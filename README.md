# iso18013-ios

The library offers a specific set of functions to handle BLE proximity as specified by iso-18013

### ISO18013-5 Proximity

#### Proximity.shared.proximityHandler

```swift
//  In order to listen for proximity events set this handler

public enum ProximityEvents {
    case onBleStart
    case onBleStop
    case onDocumentRequestReceived(request: [String: AnyHashable], json: String?)
    case onDocumentPresentationCompleted
    case onError(error: Error)
    case onLoading
}

 Proximity.shared.proximityHandler = {
    event in
    print(event)
}
```

#### Proximity.shared.ProximityEvents.onDocumentRequestReceived(request: [String: AnyHashable], json: String?)

* **request** is a json object.
* **json** is **request** as string.

Here an example:

```json
{
  "isAuthenticated": false,
  "request": {
    "eu.europa.ec.eudi.pid.1": {
      "eu.europa.ec.eudi.pid.1": {
        "resident_street": false,
        "birth_country": false,
        "birth_city": false,
        "given_name": false,
        "nationality": false,
        "issuance_date": false,
        "issuing_authority": false,
        "resident_state": false,
        "portrait_capture_date": false,
        "birth_date": false,
        "gender": false,
        "portrait": false,
        "birth_place": false,
        "given_name_birth": false,
        "family_name_birth": false,
        "administrative_number": false,
        "age_birth_year": false,
        "resident_address": false,
        "issuing_country": false,
        "family_name": false,
        "resident_city": false,
        "resident_country": false,
        "document_number": false,
        "resident_house_number": false,
        "expiry_date": false,
        "birth_state": false,
        "issuing_jurisdiction": false,
        "age_in_years": false,
        "resident_postal_code": false
      }
    }
  }
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
 * - Returns: A CBOR-encoded DeviceResponse object
 */
public func generateDeviceResponseFromJson(
    allowed: Bool,
    items: String?,
    documents: [ProximityDocument]?,
    sessionTranscript: [UInt8]?
) -> [UInt8]? 
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
 * - Returns: A CBOR-encoded DeviceResponse object
 */
public func generateDeviceResponse(
    allowed: Bool,
    items: [String: [String: [String: Bool]]]?,
    documents: [ProximityDocument]?,
    sessionTranscript: [UInt8]?
) -> [UInt8]?
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
                    
                    
guard let deviceResponse = Proximity.shared
    .generateDeviceResponse(
        allowed: allowed, 
        items: items, 
        documents: documents, 
        sessionTranscript: nil
        ) else {
    return
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