//
//  ContentView.swift
//  libIso18013-example
//
//  Created by Martina D'urso on 06/10/24.
//

import SwiftUI
import libIso18013
import SwiftCBOR

struct ContentView: View {
    
    @State private var document: Document?
    @State private var error: ErrorHandler?
    @State private var showAlert = false
    @State private var inputText = MDL.inputBase64
    @State private var displayStrings: [NameValue] = [NameValue]()
    @State private var displayImages: [NameImage] = [NameImage]()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 8) {
                CustomTextField(placeholder: "Inserisci testo...", text: $inputText)
                CustomButton(title: "Verifica documento", action: {
                    displayImages = []
                    displayStrings = []
                    do {
                        document = try LibIso18013Utils.shared.decodeDocument(base64Encoded: inputText)
                        guard let document else { return }
                        if let nameSpaces = ManageNameSpaces.getSignedItems(document.issuerSigned, document.docType) {
                            ManageNameSpaces.extractDisplayStrings(nameSpaces, &displayStrings, &displayImages)
                        }
                    } catch {
                        self.error = error
                        self.showAlert = true
                    }
                })
                
                Divider()
                    .padding()
            
                ScrollView {
                    ForEach(displayImages, id: \.name) { nameValue in
                        InfoBoxView(title: nameValue.name,
                                    docType: .bytes,
                                    subtitle: .image(nameValue.image.toImage()))
                    }
                    ForEach(displayStrings, id: \.name) { nameValue in
                        if nameValue.mdocDataType == .array,
                           let children = nameValue.children {
                            ForEach(children, id: \.name) { element in
                                InfoBoxView(title: nameValue.name,
                                            docType: nameValue.mdocDataType ?? .string,
                                            subtitle: .dictionary(element))
                            }
                        } else {
                            InfoBoxView(title: nameValue.name,
                                        docType: nameValue.mdocDataType ?? .string,
                                        subtitle: .text(nameValue.value))
                        }
                    }
                }
                Spacer()
            }
            .padding(.top)
            .navigationTitle("MDL Example")
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(error?.localizedDescription ?? "Unknown error"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

#Preview {
    ContentView()
}

