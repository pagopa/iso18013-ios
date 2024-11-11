//
//  DeviceRequestAlert.swift
//  libIso18013-example
//
//  Created by Martina D'urso on 08/11/24.
//

import SwiftUI

struct DeviceRequestAlert : View {
    
    var requested: [String: [String: [String]]]?
    @State private var allowed: [String: [String: [String: Bool]]]?
    
    @Binding var allowedBinding: [String: [String: [String: Bool]]]?
    
    var body: some View {
        
        let keys = requested?.keys.map({$0}) ?? []
        
        return VStack {
            ForEach(keys, id: \.self) {
                key in
                
                Text(key).fontWeight(.bold)
                
                let map = requested?[key] ?? [:]
                
                let mapKeys = map.keys.map({$0})
                
                ForEach(mapKeys, id: \.self) {
                    mapKey in
                    
                    let values = map[mapKey] ?? []
                    
                    Text("\(mapKey) :")
                    
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
                                allowedBinding = allowed
                            })
                            Toggle(isOn: b, label: { Text(value)
                            })
                            Spacer()
                        }
                        
                    }
                    
                }
            }
        }.padding(.horizontal, 64)
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
                    
                    items[item] = false
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
        
            let allB = Binding(get: {
                return all
            }, set: {
                k in
                all = k
            })
        return DeviceRequestAlert(requested: value, allowedBinding: allB)
    }
}

