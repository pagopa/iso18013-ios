//
//  CustomTextField.swift
//  libIso18013-example
//
//  Created by Martina D'urso on 07/10/24.
//

import SwiftUI

struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack {
            TextField(placeholder, text: $text)
                .accessibilityIdentifier("customTextField")
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .keyboardType(keyboardType)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray, lineWidth: 1)
                )
            
            if !text.isEmpty,
                text != "" {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.black)
                }
                .padding(.trailing, 8)
            }
        }
        .padding(.horizontal)
    }
}
