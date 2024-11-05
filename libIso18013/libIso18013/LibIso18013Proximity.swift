//
//  LibIso18013Proximity.swift
//  libIso18013
//
//  Created by Martina D'urso on 16/10/24.
//

// Protocol defining a listener for QR engagement events
public protocol QrEngagementListener: AnyObject {
    // Called when the connection process is starting
    func onConnecting()
    
    func didReceiveRequest(deviceRequest: DeviceRequest, sessionEncryption: SessionEncryption, onResponse: @escaping (Bool, DeviceResponse?) -> Void)
    
    func didFinishedWithError(_ error: any Error)
    
}

public class LibIso18013Proximity {
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
            
        }
        
        func didFinishedWithError(_ error: any Error) {
            listener.didFinishedWithError(error)
        }
        
        func didReceiveRequest(deviceRequest: DeviceRequest, sessionEncryption: SessionEncryption, onResponse: @escaping (Bool, DeviceResponse?) -> Void) {
            listener.didReceiveRequest(deviceRequest: deviceRequest, sessionEncryption: sessionEncryption, onResponse: onResponse)
        }
    }
}
