//
//  Image+.swift
//  libIso18013-example
//
//  Created by Martina D'urso on 07/10/24.
//

import SwiftUI

extension Data {
    func toImage() -> Image {
        if let uiImage = UIImage(data: self) {
            return Image(uiImage: uiImage)
                .resizable()
        } else {
            return Image(systemName: "exclamationmark.triangle")
                .resizable()
        }
    }
}
