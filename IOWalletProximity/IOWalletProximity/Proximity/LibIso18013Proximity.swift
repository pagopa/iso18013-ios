//
//  LibIso18013Proximity.swift
//  libIso18013
//
//  Created by Martina D'urso on 16/10/24.
//

internal import SwiftCBOR
import Foundation
import CoreBluetooth

// Protocol defining a listener for QR engagement events
protocol QrEngagementListener: AnyObject {
    // Called when the connection process is starting
    func didChangeStatus(_ newStatus: TransferStatus)
    
    func didReceiveRequest(deviceRequest: DeviceRequest, sessionEncryption: SessionEncryption, onResponse: @escaping (Bool, DeviceResponse?, UInt64) -> Void)
    
    func didFinishedWithError(_ error: any Error)
    
}

class LibIso18013Proximity: @unchecked Sendable {
    // Property to hold device engagement information
    var deviceEngagement: DeviceEngagement?
    
    var bleServer: MdocBleServer?
    var bleDelegate: MdocTransferDelegate?
    
    // Weak reference to a listener for QR engagement events
    weak var listener: QrEngagementListener?
    
    // Singleton instance of LibIso18013Proximity
    public static let shared = LibIso18013Proximity()
    
    // Sets the listener for QR engagement events
    public func setListener(_ listener: QrEngagementListener) {
        self.listener = listener
    }
    
    public func stop() {
        bleServer?.stop()
    }
    
    private var _nfc: AnyObject?
    
    // Start nfc
    @available(iOS 17.4, *)
    public func startNfc() async throws -> Bool {
        do {
            guard let deviceEngagement = self.bleServer?.deviceEngagement else {
                return false
            }
            
            let nfc: NFCEngagement = NFCEngagement(
                deviceEngagement.deviceRetrievalMethods ?? [],
                deviceEngagement: deviceEngagement.encode(options: CBOROptions()))
            
            _nfc = nfc
            
            bleServer?.handOver = nfc.handOver
            
            let success = try await nfc.start()
            return success
            
        }
        catch {
            throw ProximityError.error(error: error)
        }
        return false
    }
    
    // Stop nfc
    @available(iOS 17.4, *)
    public func stopNfc() async throws -> Bool {
        guard let nfc = _nfc as? NFCEngagement else {
            return false
        }
        
        try await nfc.stop()
        
        return true
    }
    
    
    // Generates and returns the QR code payload
    public func getQrCodePayload() throws -> String {
        
        guard let deviceEngagementBuilder = try? DeviceEngagementBuilder(pk: LibIso18013Utils.shared.createSecurePrivateKey()) else {
            throw ErrorHandler.unexpected_error
        }
        
        // Initialize device engagement with required parameters
        deviceEngagement = deviceEngagementBuilder.setDeviceRetrievalMethods([
            .ble(isBleServer: true, uuid: DeviceRetrievalMethod.getRandomBleUuid())
        ]).build()
        
        // Try to get the QR code payload from device engagement, throw an error if it is not available
        guard let qrCodePayload = deviceEngagement?.getQrCodePayload() else {
            throw ErrorHandler.qrCodePayloadNotFound
        }
        
        guard let listener = listener else {
            throw ErrorHandler.unexpected_error
        }
        
        let server = MdocBleServer()
        
        server.deviceEngagement = deviceEngagement
        
        bleServer = server
        
        self.bleDelegate = BleDelegate(listener: listener)
        
        bleServer?.delegate = bleDelegate
        
        server.status = .initialized
        
        server.start()
        
        // Return the generated QR code payload
        return qrCodePayload
    }
    
    class BleDelegate : MdocTransferDelegate {
        var listener: QrEngagementListener
        
        init(listener: QrEngagementListener) {
            self.listener = listener
        }
        
        func didChangeStatus(_ newStatus: TransferStatus) {
            listener.didChangeStatus(newStatus)
        }
        
        func didFinishedWithError(_ error: any Error) {
            listener.didFinishedWithError(error)
        }
        
        func didReceiveRequest(deviceRequest: DeviceRequest, sessionEncryption: SessionEncryption, onResponse: @escaping (Bool, DeviceResponse?, UInt64) -> Void) {
            listener.didReceiveRequest(deviceRequest: deviceRequest, sessionEncryption: sessionEncryption, onResponse: onResponse)
        }
    }
}
