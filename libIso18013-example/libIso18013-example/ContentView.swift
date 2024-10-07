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
    @State private var inputText = MDL.inputBase64
    @State var displayStrings = [NameValue]()
    @State var displayImages = [NameImage]()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 8) {
                CustomTextField(placeholder: "Inserisci testo...", text: $inputText)
                CustomButton(title: "Verifica documento", action: {
                    document = LibIso18013Utils.shared.decodeDocument(base64Encoded: inputText)
                    guard let document else { return }
                    if let nameSpaces = ManageNameSpaces.getSignedItems(document.issuerSigned, document.docType) {
                        ManageNameSpaces.extractDisplayStrings(nameSpaces, &displayStrings, &displayImages)
                    }
                })
                
                Divider()
                    .padding()
            
                ScrollView {
                    ForEach(displayImages, id: \.name) { nameValue in
                        InfoBoxView(title: nameValue.name,
                                    subtitle: .image(nameValue.image.toImage()))
                    }
                    ForEach(displayStrings, id: \.name) { nameValue in
                        InfoBoxView(title: nameValue.name,
                                    subtitle: .text(nameValue.value))
                    }
                }
                Spacer()
            }
            .padding(.top)
            .navigationTitle("MDL Example")
        }
    }
}

#Preview {
    ContentView()
}

