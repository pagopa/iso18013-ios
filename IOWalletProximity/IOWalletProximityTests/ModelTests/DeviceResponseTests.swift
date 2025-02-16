//
//  DeviceResponseTests.swift
//  libIso18013
//
//  Created by Martina D'urso on 03/10/24.
//
import XCTest
import SwiftCBOR
@testable import libIso18013

class DeviceResponseTests: XCTestCase {
    
    func testInitializerWithDefaultValues() {
        let deviceResponse = DeviceResponse(status: 200)
        
        XCTAssertEqual(deviceResponse.version, DeviceResponse.defaultVersion, "La versione del DeviceResponse non è uguale alla versione di default.")
        XCTAssertNil(deviceResponse.documents, "Documenti dovrebbe essere nil per il DeviceResponse inizializzato con valori di default.")
        XCTAssertNil(deviceResponse.documentErrors, "Gli errori dei documenti dovrebbero essere nil per il DeviceResponse inizializzato con valori di default.")
        XCTAssertEqual(deviceResponse.status, 200, "Lo stato del DeviceResponse non corrisponde a 200.")
    }
    
    func testCBORDecodingInvalidData() {
        let cbor: CBOR = .map([
            .utf8String("version"): .unsignedInt(123), // Invalid type for version
            .utf8String("status"): .unsignedInt(200)
        ])
        
        let deviceResponse = DeviceResponse(cbor: cbor)
        XCTAssertNil(deviceResponse, "DeviceResponse dovrebbe essere nil quando il CBOR contiene un tipo non valido.")
    }
    
    // test based on D.4.1.2 mdoc response section of the ISO/IEC FDIS 18013-5 document
    func testDecodeDeviceResponse() throws {
        let dr = try XCTUnwrap(DeviceResponse(data: AnnexdTestData.d412.bytes), "Decoding DeviceResponse fallito con data non valida.")
        XCTAssertEqual(dr.version, "1.0")
        let docs = try XCTUnwrap(dr.documents, "Non sono riuscito a decodificare i documenti.")
        let doc = try XCTUnwrap(docs.first, "Non ci sono documenti disponibili dopo la decodifica.")
    }
    
    func testEncodeDeviceResponse() throws {
        let cborIn = try XCTUnwrap(try CBOR.decode(AnnexdTestData.d412.bytes), "Decodifica CBOR fallita.")
        let dr = try XCTUnwrap(DeviceResponse(cbor: cborIn), "Creazione di DeviceResponse dal CBOR fallita.")
        let cborDr = dr.toCBOR(options: CBOROptions())
        XCTAssertEqual(cborIn, cborDr, "I dati CBOR originali non corrispondono ai dati CBOR codificati.")
    }
    
}
