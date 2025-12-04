//
//  NFCNDEFCard.swift
//  IOWalletProximity
//
//  Created by antoniocaparello on 04/12/25.
//


class NFCNDEFCardFileSystem {
    var root: NFCNDEFFile
    
    init(root: NFCNDEFFile) {
        self.root = root
    }
    
    private var _selected: NFCNDEFFile?
    
    func select(id: String) -> APDUStatus {
        
        print("selecting \(id)")
        
        let selected = _selected ?? root
        
        let new = selected.children.first(where: {$0.id == id}) ?? selected.root?.children.first(where: {$0.id == id}) ?? root.children.first(where: {$0.id == id})
        
        guard let new = new else {
            return .fileNotFound
        }
        
        _selected = new
        
        return .success
    }
    
    func read(offset: Int, len: Int) -> (APDUStatus, [UInt8]?) {
        guard let selected = _selected else {
            return (.fileNotFound, nil)
        }
        
        print("reading \(offset) to \(offset + len) from \(selected.id)")
        
        let value: ArraySlice<UInt8>
        
        if offset + len > selected.value.count {
            value = selected.value[offset..<selected.value.count]
        }
        else {
            value = selected.value[offset..<offset + len]
        }
        
        return (.success, [UInt8](value))
    }
}
