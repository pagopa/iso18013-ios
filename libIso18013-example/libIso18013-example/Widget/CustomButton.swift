//
//  CustomButton.swift
//  libIso18013-example
//
//  Created by Martina D'urso on 07/10/24.
//

import SwiftUI

struct CustomButton: View {
    var title: String
    var action: () -> Void
    var backgroundColor: Color = .blue
    var textColor: Color = .white
    var cornerRadius: CGFloat = 10
    
    var body: some View {
        Button(action: {
            action()
        }) {
            Text(title)
                .font(.headline)
                .foregroundColor(textColor)
                .padding()
                .frame(maxWidth: .infinity)
                .background(backgroundColor)
                .cornerRadius(cornerRadius)
        }
        .padding(.horizontal)
    }
}

struct CustomButton_Previews: PreviewProvider {
    static var previews: some View {
        CustomButton(title: "Clicca qui", action: {
            print("Bottone premuto")
        })
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
