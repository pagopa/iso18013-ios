//
//  Cose1SignView.swift
//  Demo-mdl
//
//  Created by Antonio on 07/10/24.
//

import SwiftUI
import SwiftCBOR
import cbor
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
                            let cosePrivateKey = CborCose.createSecurePrivateKey()!
                            
                            deviceKey = cosePrivateKey
                            
                            setKeyPair(coseKey: cosePrivateKey)
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
                            
                            let payload = input.data(using: .utf8)!
                            
                            output = CborCose.sign(data: payload, privateKey: cosePrivateKey).base64EncodedString()
                        })
                    }, label: {
                        Text("Input")
                    })
                    
                    GroupBox(content: {
                        CustomTextField(placeholder: "Firma", text: $output)
                        
                        CustomButton(title: "Verifica Firma", action: {
                            let cosePublicKey = CoseKey(crv: .p256, x963Representation: Data(base64Encoded: publicKey)!)
                            
                            let data = Data(base64Encoded: output)!
                            
                            verified = CborCose.verify(data: data, publicKey: cosePublicKey)
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
