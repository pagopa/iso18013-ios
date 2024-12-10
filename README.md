# iso18013-ios

### Proximity

The library offers a specific set of functions to handle BLE proximity as specified by iso-18013


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


#### Proximity.shared.dataPresentation

```swift
//  Responds to a request for data from the reader.
//  - Parameters:
//      - allowed: User has allowed the verification process
//      - items: Map of [documentType: [nameSpace: [elementIdentifier: allowed]]]
//      - documents: Map of documents. Key is docType, first item is document as cbor and second item is CoseKeyPrivate encoded (can rapresent keytag or raw private key)

let items: [String: [String: [String: Bool]]] = [:]

let documents = LibIso18013DAOKeyChain().getAllDocuments(state: .issued).compactMap({
    document in
    if let documentData = document.documentData {
        return (document.docType, documentData, document.deviceKeyData)
    }
    return nil
})
                    
var documentMap: [String: ([UInt8], [UInt8])] = [:]

documents.forEach({
    document in
    documentMap[document.0] = (document.1, document.2)
})
                    
Proximity.shared.dataPresentation(allowed: allowed, items: items, documents: documentMap)
```