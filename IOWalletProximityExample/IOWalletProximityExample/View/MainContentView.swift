//
//  MainContentView.swift
//  IOWalletProximityExample
//
//  Created by Martina D'urso on 09/10/24.
//

import SwiftUI

enum SelectedView {
    case none
    case qrCodeView
    case documentsView
}

struct MainContentView: View {
    @State private var isMenuOpen: Bool = false
    @State private var selectedView: SelectedView = .qrCodeView
    
    var body: some View {
        ZStack {
            NavigationView {
                VStack {
                    switch selectedView {
                        case .qrCodeView:
                            QRCodeView()
                        case .none:
                            Text("Seleziona una vista dal menu")
                                .padding()
                        case .documentsView:
                            DocumentDAOView()
                    }
                    Spacer()
                }
                .navigationBarItems(leading: Button(action: {
                    withAnimation {
                        isMenuOpen.toggle()
                    }
                }) {
                    Image(systemName: "line.horizontal.3")
                        .foregroundColor(.primary)
                })
            }
            .disabled(isMenuOpen) // Disable interaction with the main view when the menu is open
            
            if isMenuOpen {
                SideMenu(isMenuOpen: $isMenuOpen, selectedView: $selectedView)
                    .transition(.move(edge: .leading))
                    .zIndex(1) // Ensures the menu is on top
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct SideMenu: View {
    @Binding var isMenuOpen: Bool
    @Binding var selectedView: SelectedView
    
    var body: some View {
        HStack {
            ZStack {
                Rectangle()
                    .fill(Color.white)
                    .frame(width: UIScreen.main.bounds.width / 2)
                    .shadow(color: .purple.opacity(0.1), radius: 5, x: 0, y: 3)
                
                VStack(alignment: .leading, spacing: 0) {
                
                    Button(action: {
                        selectedView = .qrCodeView
                        isMenuOpen = false
                    }) {
                        rowView(isSelected: selectedView == .qrCodeView, imageName: "house", title: "QRCode")
                    }
                    Button(action: {
                        selectedView = .documentsView
                        isMenuOpen = false
                    }) {
                        rowView(isSelected: selectedView == .documentsView, imageName: "key", title: "Documents")
                    }
                    
                    Spacer()
                }
                .padding(.top, 100)
                .frame(width: UIScreen.main.bounds.width / 2)
            }
            Spacer()
        }
    }
    
    func rowView(isSelected: Bool, imageName: String, title: String) -> some View {
        VStack(alignment: .leading) {
            HStack(spacing: 20) {
                Rectangle()
                    .fill(isSelected ? Color.purple : Color.white)
                    .frame(width: 5)
                
                ZStack {
                    Image(systemName: imageName)
                        .renderingMode(.template)
                        .foregroundColor(isSelected ? .black : .gray)
                        .frame(width: 26, height: 26)
                }
                .frame(width: 30, height: 30)
                Text(title)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(isSelected ? .black : .gray)
                Spacer()
            }
        }
        .frame(height: 50)
        .background(
            LinearGradient(colors: [isSelected ? Color.purple.opacity(0.5) : Color.white, Color.white], startPoint: .leading, endPoint: .trailing)
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainContentView()
    }
}
