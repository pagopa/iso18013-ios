//
//  DeviceRetrievalMethod+.swift
//  IOWalletProximity
//
//  Created by antoniocaparello on 03/12/25.
//

import CoreNFC

extension DeviceRetrievalMethod {
    func toNdefRecord(
        _ auxiliaryReferences: [String],
        _ isForHandoverSelect: Bool
    ) -> (NFCNDEFPayload, Data)? {
        
        switch(self) {
        case .qr:
            return nil
        case .ble(let isBleServer, let uuid):
            return toNdefRecordBLE(isBleServer, uuid, auxiliaryReferences, isForHandoverSelect)
        }
        
    }
    
    private func toNdefRecordBLE(
        _ isBleServer: Bool,
        _ uuidString: String,
        _ auxiliaryReferences: [String],
        _ isForHandoverSelect: Bool) -> (NFCNDEFPayload, Data)? {
            
            let uuidData = uuidString.byteArray
            
            let uuidValue: UUID = Data(uuidData).object()
            
            let supportsCentralClientMode = !isBleServer
            let supportsPeripheralServerMode = isBleServer
            // -------------------------------------------
            // Determine LE Role (same logic as Android)
            // -------------------------------------------
            
            let leRole: UInt8
            var uuid: UUID? = nil
            
            if supportsCentralClientMode {
                 leRole = isForHandoverSelect ? 0x01 : 0x00
                 uuid = uuidValue
                 
             } else if supportsPeripheralServerMode {
                 leRole = isForHandoverSelect ? 0x00 : 0x01
                 uuid = uuidValue
                 
             } else {
                 fatalError("BLE ConnectionMethod must support at least one mode")
             }
            
            // -------------------------------------------
            // Construct OOB data (AD structures)
            // -------------------------------------------
            
            var oob = Data()
            
            // ---- LE Role (length=2, type=0x1C) ----
            oob.append(0x02)           // length
            oob.append(0x1C)           // AD type
            oob.append(leRole)         // value
            
            // ---- 128-bit UUID (AD type 0x07) ----
            if let uuid = uuid {
                oob.append(0x11)       // length = 1 (type) + 16 bytes
                oob.append(0x07)       // AD type = Complete List 128-bit UUIDs
                
                // Convert UUID to BLE little-endian 128-bit
                let uuidLE = uuidToLittleEndian(uuid)
                oob.append(uuidLE)
            }
            
            // -------------------------------------------
            // Build Carrier Configuration Record (NFC MIME MEDIA)
            // -------------------------------------------
            let ccr = NFCNDEFPayload(
                format: .media,
                type: "application/vnd.bluetooth.le.oob".data(using: .utf8)!,
                identifier: "0".data(using: .utf8)!,
                payload: oob
            )
            
            // -------------------------------------------
            // Build Alternative Carrier Record Payload
            // -------------------------------------------
            
            var acrPayload = Data()
            
            // CPS = Active
            acrPayload.append(0x01)
            
            // Carrier data reference = "0"
            acrPayload.append(0x01)
            acrPayload.append(UInt8(ascii: "0"))
            
            // Auxiliary references
            acrPayload.append(UInt8(auxiliaryReferences.count))
            for aux in auxiliaryReferences {
                let ref = aux.data(using: .utf8)!
                acrPayload.append(UInt8(ref.count))
                acrPayload.append(ref)
            }
            
            return (ccr, acrPayload)
            
        }
    
    // -------------------------------------------------
    // Helper: Convert Foundation.UUID → 128-bit LE format
    // -------------------------------------------------
    private func uuidToLittleEndian(_ uuid: UUID) -> Data {
        var uuidBytes = uuid.uuid
        // BLE expects full 16-byte UUID LE (LSB first)
        return Data(Data(bytes: &uuidBytes, count: 16).reversed())
    }
}



