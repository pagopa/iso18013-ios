//
//  LibIso18013Proximity.swift
//  libIso18013
//
//  Created by Martina D'urso on 16/10/24.
//

public protocol QrEngagementListener: AnyObject {
    func onConnecting()
}

public class LibIso18013Proximity {
    var deviceEngagement: DeviceEngagement?

    weak var listner: QrEngagementListener?

    public static let shared = LibIso18013Proximity()
    
    public func setListner(_ listner: QrEngagementListener) {
        self.listner = listner
    }
    
    public func getQrCodePayload() throws -> String {
        deviceEngagement = DeviceEngagement(isBleServer: true, crv: .p256, rfus: nil)
        guard let qrCodePayload = deviceEngagement?.getQrCodePayload() else {
            throw ErrorHandler.qrCodePayloadNotFound
        }
        return qrCodePayload
    }
}
