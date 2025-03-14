//
//  InfoBoxView.swift
//  IOWalletProximityExample
//
//  Created by Martina D'urso on 06/10/24.
//

import SwiftUI
import IOWalletProximity

struct InfoBoxView: View {
    
    let title: String
    let docType: MdocDataType
    let subtitle: SubtitleType
    
    enum SubtitleType {
        case text(String)
        case image(Image)
        case dictionary(NameValue)
    }
    
    var body: some View {
        GroupBox {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(title)
                            .font(.subheadline)
                            .accessibilityIdentifier("InfoBoxViewTitle")
                        Spacer()
                        Text(docType.rawValue)
                            .font(.subheadline)
                            .accessibilityIdentifier("InfoBoxViewDocType")
                    }
                    switch subtitle {
                        case .text(let text):
                            Text(text)
                                .font(.title2)
                                .accessibilityIdentifier("InfoBoxViewSubtitle")
                        case .image(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(height: 50)
                                .accessibilityIdentifier("InfoBoxViewSubtitleImage")
                        case .dictionary(let dict):
                            if let children = dict.children {
                                ForEach(children, id: \.name) { element in
                                    InfoBoxView(title: element.name,
                                                docType: element.mdocDataType ?? .string,
                                                subtitle: .text(element.value))
                                }
                            }
                    }
                }
                Spacer()
            }
        }
        .cornerRadius(6)
        .padding(.horizontal)
    }
}

#Preview {
    InfoBoxView(title: "Nome",
                docType: .string,
                subtitle: .text("Alessandro"))

    InfoBoxView(title: "Foto",
                docType: .bytes,
                subtitle: .image(Image(systemName: "star")))

}
