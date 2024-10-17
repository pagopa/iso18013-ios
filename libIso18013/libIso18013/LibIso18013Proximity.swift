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
}

public class LibIso18013Proximity {
    // Property to hold device engagement information
    var deviceEngagement: DeviceEngagement?
    
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
        // Initialize device engagement with required parameters
        deviceEngagement = DeviceEngagement(isBleServer: true, crv: .p256, rfus: nil)
        
        // Try to get the QR code payload from device engagement, throw an error if it is not available
        guard let qrCodePayload = deviceEngagement?.getQrCodePayload() else {
            throw ErrorHandler.qrCodePayloadNotFound
        }
        
        // Return the generated QR code payload
        return qrCodePayload
    }
}
