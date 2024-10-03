//
//  CBOR+.swift
//  libIso18013
//
//  Created by Antonio on 02/10/24.
//

import SwiftCBOR
import OrderedCollections

extension CBOR: @retroactive CustomStringConvertible {
  public var description: String {
    switch self {
    case .utf8String(let str): return str
    case .tagged(let tag, .utf8String(let str)):
      if tag.rawValue == 1004 || tag == .standardDateTimeString { return str.toPosixDate() }
      return str
    case .unsignedInt(let i): return String(i)
    case .boolean(let b): return String(b)
    case .simple(let n): return String(n)
    default: return ""
    }
  }
}

extension CBOR: @retroactive CustomDebugStringConvertible {
  public var debugDescription: String {
    switch self {
    case .utf8String(let str): return "'\(str)'"
    case .byteString(let bs): return "ByteString \(bs.count)"
    case .tagged(let tag, .utf8String(let str)): return "tag \(tag.rawValue) '\(str)'"
    case .tagged(let tag, .byteString(let bs)): return "tag \(tag.rawValue) 'ByteString \(bs.count)'"
    case .unsignedInt(let i): return String(i)
    case .boolean(let b): return String(b)
    case .array(let a): return "[\(a.reduce("", { $0 + ($0.count > 0 ? "," : "") + " \($1.debugDescription)" }))]"
    case .map(let m): return "{\(m.reduce("", { $0 + ($0.count > 0 ? "," : "") + " \($1.key.debugDescription): \($1.value.debugDescription)" }))}"
    case .null: return "Null"
    case .simple(let n): return String(n)
    default: return "Other"
    }
  }
}

extension CBOR {
  public var mdocDataType: MdocDataType? {
    switch self {
    case .utf8String(_), .null: return .string
    case .byteString(_): return .bytes
    case .map(_): return .dictionary
    case .array(_): return .array
    case .boolean(_): return .boolean
    case .tagged(.standardDateTimeString, _): return .date
    case .tagged(Tag(rawValue: 1004), _): return .date
    case .tagged(_, .utf8String(_)): return .string
    case .simple(_), .unsignedInt(_): return .integer
    case .float(_), .double(_): return .double
    default:
      return nil
    }
  }
}

extension CBOR {
  public func fullDate() -> String? {
    guard case let CBOR.tagged(tag, cborEncoded) = self,
          tag.rawValue == 1004,
          case let .utf8String(decodedString) = cborEncoded else {
      return nil
    }
    return decodedString
  }
}

extension CBOR {
  public func unwrap() -> Any? {
    switch self {
    case .simple(let value): return value
    case .boolean(let value): return value
    case .byteString(let value): return value
    case .date(let value): return value
    case .double(let value): return value
    case .float(let value): return value
    case .half(let value): return value
    case .tagged(let tag, let cbor): return (tag, cbor)
    case .array(let array): return array
    case .map(let map): return map
    case .utf8String(let value): return value
    case .negativeInt(let value): return value
    case .unsignedInt(let value): return value
    default:
      return nil
    }
  }
  
  public func asUInt64() -> UInt64? {
    return self.unwrap() as? UInt64
  }
  
  public func asDouble() -> Double? {
    return self.unwrap() as? Double
  }
  
  public func asInt64() -> Int64? {
    return self.unwrap() as? Int64
  }
  
  public func asString() -> String? {
    return self.unwrap() as? String
  }
  
  public func asList() -> [CBOR]? {
    return self.unwrap() as? [CBOR]
  }
  
  public func asMap() -> OrderedDictionary<CBOR, CBOR>? {
    return self.unwrap() as? OrderedDictionary<CBOR, CBOR>
  }
  
  public func asBytes() -> [UInt8]? {
    return self.unwrap() as? [UInt8]
  }
  
  public func asData() -> Data {
    return Data(self.encode())
  }
  
  public static func asDateString(_ tag: Tag, _ value: CBOR) -> Any {
    if tag.rawValue == 1004 || tag == .standardDateTimeString, let strDate = value.unwrap() as? String {
      return strDate.toPosixDate()
    } else {
      return value.unwrap() ?? ""
    }
  }

}

/// Methods to cast collections of CBOR types in the form of the dictionary/list
extension CBOR {
  public static func decodeList(_ list: [CBOR], unwrap: Bool = true, base64: Bool = false) -> [Any] {
    list.map { val in decodeCborVal(val, unwrap: unwrap, base64: base64) }
  }
  
  public static func decodeDictionary(_ dictionary: OrderedDictionary<CBOR, CBOR>, unwrap: Bool = true, base64: Bool = false) -> OrderedDictionary<String, Any> {
    var payload = OrderedDictionary<String, Any>()
    for (key, val) in dictionary {
      if let key = key.asString() {
        payload[key] = decodeCborVal(val, unwrap: unwrap, base64: base64)
      }
    }
    return payload
  }
  
  public static func decodeCborVal(_ val: CBOR, unwrap: Bool, base64: Bool) -> Any {
    if unwrap, case .map(let d) = val {
      return decodeDictionary(d, unwrap: unwrap)
    } else if unwrap, case .array(let a) = val {
      return decodeList(a, unwrap: unwrap)
    } else if unwrap, case .tagged(let t, let v) = val {
      return CBOR.asDateString(t, v)
    } else if unwrap, case .byteString(let bytes) = val {
      return if base64 { Data(bytes).base64EncodedString() } else { bytes }
    } else if unwrap, let unwrappedValue = val.unwrap() {
      return unwrappedValue
    } else {
      return val
    }
  }
  
  public func getTypedValue<T>() -> T? {
    if T.self == DrivingPrivileges.self { return DrivingPrivileges(cbor: self) as? T }
    else if case let .tagged(tag, cbor) = self {
      if T.self == String.self, tag.rawValue == 1004 || tag == .standardDateTimeString {
        let strDate = cbor.unwrap() as? String
        return strDate?.toPosixDate() as? T
      }
      return cbor.unwrap() as? T
    }
    return self.unwrap() as? T
  }
}
