//
//  NFCCardEmulator.swift
//  IOWalletProximity
//
//  Created by antoniocaparello on 04/12/25.
//

import CoreNFC

@available(iOS 17.4, *)
class NFCCardEmulator : @unchecked Sendable {
    var delegate: NFCCardEmulatorDelegate
    
    init(delegate: NFCCardEmulatorDelegate) {
        self.delegate = delegate
    }
    
    private func processAPDU(_ cardSession: CardSession, _ capdu: Data) -> Data {
        if let apduRequest = APDURequest(apdu: [UInt8](capdu)) {
            
            print(apduRequest)
            print(apduRequest.debugDescription)
            
            
            let apduResponse = delegate.processAPDU(cardSession, apduRequest)
            
            
            print(apduResponse)
            
            return Data(apduResponse.raw)
            
        }
        
        let apduResponse = APDUResponse([], .fileNotFound, extended: false)
        
        return Data(apduResponse.raw)
    }
    
    var cardSession: CardSession?
    var presentmentIntent: NFCPresentmentIntentAssertion?
    
    func stop() async throws {
        await cardSession?.stopEmulation(status: .success)
        cardSession?.invalidate()
    }
    
    func start() async throws -> Bool {
        // Proceed only if the current device and system are able and
        // eligible to use CardSession.
        guard NFCReaderSession.readingAvailable,
              CardSession.isSupported,
              await CardSession.isEligible else {
            return false
        }
        
        Task {
            
            
            
            
            // Hold a presentment intent assertion reference to prevent the
            // default contactless app from launching. In a real app, monitor
            // presentmentIntent.isValid to ensure the assertion remains active.
            var presentmentIntent: NFCPresentmentIntentAssertion?
            
            
            let cardSession: CardSession
            do {
                presentmentIntent = try await NFCPresentmentIntentAssertion.acquire()
                cardSession = try await CardSession()
                
            } catch {
                /// Handle failure to acquire NFC presentment intent assertion or
                /// card session.
                return
            }
            
            
            // Iterate over events as the card session produces them.
            for try await event in cardSession.eventStream {
                print(event)
                
                switch event {
                case .sessionStarted:
                    cardSession.alertMessage = String(localized: "Communicating with card reader.")
                    break
                    
                case .readerDetected:
                    /// Start card emulation on first detection of an external reader.
                    try await cardSession.startEmulation()
                    
                case .readerDeselected:
                    /// Stop emulation on first notification of RF link loss.
                    await cardSession.stopEmulation(status: .success)
                    cardSession.invalidate()
                    
                case .received(let cardAPDU):
                    do {
                        //cardSession.alertMessage = cardAPDU.payload.hexEncodedString()
                        /// Call handler to process received input and produce a response.
                        let responseAPDU = processAPDU(cardSession, cardAPDU.payload)
                        
                        try await cardAPDU.respond(response: responseAPDU)
                    } catch {
                        print(error)
                        /// Handle the error from respond(response:). If the error is
                        /// CardSession.Error.transmissionError, then retry by calling
                        /// CardSession.APDU.respond(response:) again.
                    }
                    
                case .sessionInvalidated(reason: _):
                    cardSession.alertMessage = String(localized: "Ending communication with card reader.")
                    /// Handle the reason for session invalidation.
                    await cardSession.stopEmulation(status: .success)
                    break
                @unknown default:
                    print("unknown event")
                }
            }
            
            presentmentIntent = nil /// Release presentment intent assertion.
        }
        
        
        
        return true
    }
    
}

@available(iOS 17.4, *)
protocol NFCCardEmulatorDelegate : Sendable {
    func processAPDU(_ cardSession: CardSession, _ apduRequest: APDURequest) -> APDUResponse
}
