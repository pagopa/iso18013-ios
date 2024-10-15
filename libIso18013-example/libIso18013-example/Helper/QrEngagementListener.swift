//
//  QrEngagementListener.swift
//  libIso18013-example
//
//  Created by Martina D'urso on 15/10/24.
//


protocol QrEngagementListener {
    func onConnecting()
    func onDeviceRetrievalHelperReady(deviceRetrievalHelper: String)
    func onCommunicationError(msg: String)
    func onNewDeviceRequest(deviceRequestBytes: [UInt8])
    func onDeviceDisconnected(transportSpecificTermination: Bool)
}
