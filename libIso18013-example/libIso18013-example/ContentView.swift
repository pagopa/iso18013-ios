//
//  ContentView.swift
//  libIso18013-example
//
//  Created by Martina D'urso on 06/10/24.
//

import SwiftUI
import libIso18013

struct ContentView: View {
    
   var body: some View {
        VStack {
            InfoBoxView(title: "Nome",
                        subtitle: .text("Alessandro"))
            
            InfoBoxView(title: "Foto",
                        subtitle: .image(Image(systemName: "star")))
        }
        .task {
            LibIso18013Utils.decodeDocument(base64Encoded: MDL.inputBase64)
        }
    }
}

#Preview {
    ContentView()
}
