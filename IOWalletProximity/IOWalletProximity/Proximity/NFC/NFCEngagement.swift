//
//  NFCEngagement.swift
//  IOWalletProximity
//
//  Created by antoniocaparello on 14/11/25.
//
import CoreNFC
internal import SwiftCBOR


public enum ProximityNfcEvents {
    //The device is ready to present nfc document
    case onStart
    
    //The device has stopped presenting nfc
    case onStop
    
}

@available(iOS 17.4, *)
class NFCEngagement : @unchecked Sendable, NFCCardEmulatorDelegate {
    
    public var nfcHandler: ((ProximityNfcEvents) -> Void)?
    
    func emulationStatusChanged(_ event: CardSession.Event) {
        switch(event) {
        case .sessionInvalidated(let reason):
            nfcHandler?(.onStop)
            break
        default:
            break
        }
    }
    
    
    private var ndef: [UInt8]
    private lazy var cardEmulator: NFCCardEmulator = NFCCardEmulator(delegate: self)
    
    init(_ retrivalMethods: [DeviceRetrievalMethod], deviceEngagement: [UInt8]) {
        let ndef = NfcUtils().createNdefMessageHandoverSelect(methods: retrivalMethods, encodedDeviceEngagement: Data(deviceEngagement)).bytes
        
        self.ndef = ndef
        
        self.nfcRoot = NFCNDEFCardFileSystem(root:
                                                NFCNDEFFile(id: "", children: [
                                                    NFCNDEFFile(id: "d2760000850101",
                                                                children: [
                                                                    //CAPABILITY_CONTAINER_FILE
                                                                    NFCNDEFFile(id: "e103", value: [
                                                                        0x00, 0x0f,
                                                                        0x20,
                                                                        0x7f, 0xff,
                                                                        0x7f, 0xff,
                                                                        0x04, 0x06,
                                                                        0xe1, 0x04,
                                                                        0x7f, 0xff,
                                                                        0x00,
                                                                        0xff
                                                                    ]),
                                                                    //NDEF_FILE
                                                                    NFCNDEFFile(id: "e104", value: Utils.intToBin(ndef.count, pad: 4) + ndef)
                                                                ]),
                                                ]))
    }
    
    var handOver: CBOR {
        return CBOR.array([
            CBOR.byteString(ndef),
            CBOR.null
        ])
    }
    
    var nfcRoot: NFCNDEFCardFileSystem
    
    internal func processAPDU(_ cardSession: CardSession, _ apduRequest: APDURequest) -> APDUResponse {
        print(apduRequest)
        
        var apduResponse: APDUResponse = APDUResponse([], .fileNotFound, extended: false)
        
        guard let instruction = APDUInstruction(rawValue: apduRequest.head.instruction) else {
            return apduResponse
        }
        
        switch(instruction) {
        case .SELECT:
            let id = apduRequest.data.hexEncodedString
            
            let status = nfcRoot.select(id: id)
            
            apduResponse = APDUResponse([], status, extended: false)
            break
        case .READ_BINARY:
            let offset = UInt16(low: apduRequest.head.p2, high: apduRequest.head.p1)
            
            let len = Int(apduRequest.le.hexEncodedString, radix: 16)!
            
            let (status, data) = nfcRoot.read(offset: Int(offset), len: len)
            
            apduResponse = APDUResponse(data ?? [], status, extended: apduRequest.le.count > 1)
            break
        default:
            break
        }
        
        return apduResponse
    }
    
    
    func start() async throws -> Bool {
        return try await cardEmulator.start()
    }
    
    func stop() async throws {
        return try await cardEmulator.stop()
    }
}
