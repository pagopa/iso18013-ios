//
//  DeviceRequestAlert.swift
//  IOWalletProximityExample
//
//  Created by Martina D'urso on 08/11/24.
//

import SwiftUI

struct DeviceRequestAlert : View {
    var isAuthenticated: Bool = false
    var requested: [String: [String: [String]]]?
    
    @State private var allowed: [String: [String: [String: Bool]]]?
    
    var response: ((Bool, [String: [String: [String: Bool]]]?) -> Void)?
    
    var body: some View {
        
        let keys = requested?.keys.map({$0}) ?? []
        
        return  ZStack(alignment: Alignment(horizontal: .center, vertical: .center)) {
            
            Color.black.opacity(0.5).edgesIgnoringSafeArea(.all)
            ScrollView(.vertical) {
                VStack {
                    Text("isAuthenticated: \(isAuthenticated)").foregroundStyle(isAuthenticated ? Color.green : Color.red)
                }
                .padding(32)
                .background(Color.white)
                .cornerRadius(12)
                .frame(alignment: .center)
                .padding(.horizontal, 12)
                VStack {
                    ForEach(keys, id: \.self) {
                        key in
                        
                        Text(key)
                            .foregroundStyle(Color.black)
                            .fontWeight(.bold)
                        
                        let map = requested?[key] ?? [:]
                        
                        let mapKeys = map.keys.map({$0})
                        
                        ForEach(mapKeys, id: \.self) {
                            mapKey in
                            
                            let values = map[mapKey] ?? []
                            
                            Text("\(mapKey) :")
                                .foregroundStyle(Color.black)
                            
                            ForEach(values, id: \.self) {
                                value in
                                HStack {
                                    let b = Binding(get: {
                                        return allowed?[key]?[mapKey]?[value] ?? false
                                    }, set: {
                                        v in
                                        
                                        let a = allowed ?? [:]
                                        
                                        allowed = a
                                        
                                        let i = allowed?[key] ?? [:]
                                        allowed?[key] = i
                                        let j = allowed?[key]?[mapKey] ?? [:]
                                        
                                        allowed?[key]?[mapKey] = j
                                        
                                        allowed?[key]?[mapKey]?[value] = v
                                    })
                                    Toggle(isOn: b, label: {
                                        Text(value)
                                            .foregroundStyle(Color.black)
                                    })
                                    Spacer()
                                }
                                
                            }
                            
                        }
                    }
                    HStack {
                        Spacer()
                        Button {
                            response?(true, allowed)
                        } label: {
                            Text("Yes")
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Rectangle().fill(Color.blue).cornerRadius(8))
                        }
                        Spacer()
                        Button {
                            response?(false, allowed)
                        } label: {
                            Text("No")
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Rectangle().fill(Color.red).cornerRadius(8))
                        }
                        Spacer()
                    }
                    .padding()
                    
                }
                .padding(32)
                .background(Color.white)
                .cornerRadius(12)
                .frame(alignment: .center)
                .padding(.horizontal, 12)
                .onAppear {
                    allowed = genValues(value: requested)
                }
            }
            
        }
        
    }
    
    func genValues(value: [String: [String: [String]]]?) -> [String: [String: [String: Bool]]]? {
        var all: [String: [String: [String: Bool]]]? = [String: [String: [String: Bool]]]()
        
        value?.forEach({
            keyPair in
            
            var ns = [String:[String:Bool]]()
            
            keyPair.value.forEach({
                keyPair2 in
                
                var items = [String: Bool]()
                
                keyPair2.value.forEach({
                    item in
                    
                    items[item] = true
                })
                
                ns[keyPair2.key] = items
                
            })
            
            all?[keyPair.key] = ns
        })
        
        return all
    }
}

struct DeviceRequestAlert_Previews: PreviewProvider {
    static var previews: some View {
        let value = ["mdl": ["hello": ["world"]], "euPid": ["hello": ["world", "map"]]]
        
        var all: [String: [String: [String: Bool]]]? = [String: [String: [String: Bool]]]()
        
        
        return DeviceRequestAlert(requested: value) { allowed, values in
            print(allowed, values)
        }
    }
}

