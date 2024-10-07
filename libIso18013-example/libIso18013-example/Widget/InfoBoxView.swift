//
//  InfoBoxView.swift
//  libIso18013-example
//
//  Created by Martina D'urso on 06/10/24.
//

import SwiftUI

struct InfoBoxView: View {
    
    let title: String
    let subtitle: SubtitleType
    
    enum SubtitleType {
        case text(String)
        case image(Image)
    }
    
    var body: some View {
        GroupBox {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.subheadline)
                        .accessibilityIdentifier("InfoBoxViewTitle")
                    
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
                subtitle: .text("Alessandro"))

    InfoBoxView(title: "Foto",
                subtitle: .image(Image(systemName: "star")))

}
