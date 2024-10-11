//
//  Cose1SignView.swift
//  Demo-mdl
//
//  Created by Antonio on 07/10/24.
//

import SwiftUI
import SwiftCBOR
import libIso18013

struct Cose1SignView : View {
    @State var privateKey: String = ""
    @State var publicKey: String = ""
    @State var deviceKey: CoseKeyPrivate? = nil
    @State var input: String = ""
    @State var output: String = ""
    @State var verified: Bool? = nil
    
    func setKeyPair(coseKey: CoseKeyPrivate) {
        if coseKey.secureEnclaveKeyID == nil {
            privateKey = coseKey.getx963Representation().base64EncodedString()
        }
        else {
            privateKey = "Secure Enclave Key"
        }
        
        publicKey = coseKey.key.getx963Representation().base64EncodedString()
        
        self.deviceKey = coseKey
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    GroupBox(content: {
                        GroupBox(content: {
                            CustomTextField(placeholder: "Chiave Privata", text: $privateKey)
                        }, label: {
                            Text("Privata")
                        })
                        GroupBox(content: {
                            CustomTextField(placeholder: "Chiave Pubblica", text: $publicKey)
                            
                        }, label: {
                            Text("Pubblica")
                        })
                        CustomButton(title: "Nuova coppia", action: {
                            let cosePrivateKey = CoseKeyPrivate(crv: .p256)
                            
                            deviceKey = cosePrivateKey
                            
                            setKeyPair(coseKey: cosePrivateKey)
//                            self.privateKey = cosePrivateKey.getx963Representation().base64EncodedString()
//                            self.publicKey = cosePrivateKey.key.getx963Representation().base64EncodedString()
                        })
                    }, label: {
                        Text("Coppia di chiavi")
                    })
                    GroupBox(content: {
                        CustomTextField(placeholder: "Input", text: $input)
                        CustomButton(title: "Firma Input", action: {
                            guard let cosePrivateKey = self.deviceKey else {
                                return
                            }
//                            let cosePrivateKey = CoseKeyPrivate(privateKeyx963Data: Data(base64Encoded: privateKey)!)
                            
                            let payload = input.data(using: .utf8)!
                            
                            let cose = try! Cose.makeCoseSign1(payloadData: payload, deviceKey: cosePrivateKey, alg: .es256)
                            
                            output = Data(cose.encode(options: CBOROptions())).base64EncodedString()
                        })
                    }, label: {
                        Text("Input")
                    })
                    
                    GroupBox(content: {
                        CustomTextField(placeholder: "Firma", text: $output)
                        
                        CustomButton(title: "Verifica Firma", action: {
                            let coseKey = CoseKey(crv: .p256, x963Representation: Data(base64Encoded: publicKey)!)
                            
                            let coseCBOR = try? CBOR.decode(Data(base64Encoded: output)!.bytes)
                            
                            let cose = Cose.init(type: .sign1, cbor: coseCBOR!)!
                            
                            verified = try! cose.validateCoseSign1(publicKey_x963: coseKey.getx963Representation())
                            
                            input = String(data: Data(cose.payload.asBytes()!), encoding: .utf8) ?? ""
                        })
                        Text("La firma è \(verified  == true ? "valida" : verified == false ? "non valida" : "sconosciuta")")
                    }, label: {
                        Text("Firma")
                    })
                    
                    Spacer()
                }
                .padding(.top)
                .navigationTitle("COSE Example")
            }.onAppear {
                if let deviceKey = self.deviceKey {
                    self.setKeyPair(coseKey: deviceKey)
                }
            }
        }
    }
}

#Preview {
    Cose1SignView()
}
