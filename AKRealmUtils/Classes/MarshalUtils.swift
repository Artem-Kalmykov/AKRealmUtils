//
//  MarshalUtils.swift
//  AKRealmUtils
//
//  Created by Artem Kalmykov on 10/17/17.
//

import Foundation
import Marshal
import RealmSwift

extension Dictionary: ValueType {
    public static func value(from object: Any) throws -> Value {
        guard let dict = object as? Value else {
            throw MarshalError.typeMismatch(expected: String.self, actual: type(of: object))
        }

        return dict
    }
}

extension JSONParser {
    public static var dictionaryKey: String {
        return "_Marshal_DictionaryKey"
    }
    
    public static var dictionaryValue: String {
        return "_Marshal_DictionaryValue"
    }
}

extension MarshaledObject {
    public func valueForDictionaryKey<T: ValueType>() throws -> T {
        return try self.value(for: JSONParser.dictionaryKey)
    }
    
    public func valueForDictionaryValue<T: ValueType>() throws -> T {
        return try self.value(for: JSONParser.dictionaryValue)
    }
    
    public func valueForDictionaryKey<T: ValueType>() throws -> [T] {
        return try self.value(for: JSONParser.dictionaryKey)
    }
    
    public func valueForDictionaryValue<T: ValueType>() throws -> [T] {
        return try self.value(for: JSONParser.dictionaryValue)
    }
    
    public func dictionaryTransformedValues<T: ValueType>(for key: KeyType) throws -> [T] {
        guard let castedSelf = self as? [AnyHashable : Any] else {
            return []
        }
        
        return try castedSelf.dictionaryTransformedValues(for: key)
    }
    
    public func transformDictionaryValues<T: ValueType>() throws -> [T] {
        guard let castedSelf = self as? [AnyHashable : Any] else {
            return []
        }
        
        return try castedSelf.transformDictionaryValues()
    }
    
    public func combinedDictionaryOfDictionariesOfArrays<T: ValueType>(for key: KeyType) throws -> [T] {
        guard let dictValue: [String : Any] = try self.value(for: key), dictValue is [String : [[String : Any]]] else {
            throw MarshalError.typeMismatchWithKey(key: key.stringValue, expected: [AnyHashable : Any].self, actual: self.self)
        }
        
        var transformed: [[String : Any]] = []
        
        for obj in (dictValue as! [String : [[String : Any]]]) {
            for var subObj in obj.value {
                subObj[JSONParser.dictionaryKey] = obj.key
                transformed.append(subObj)
            }
        }
        
        return try transformed.map {
            let value = try T.value(from: $0)
            guard let element = value as? T else {
                throw MarshalError.typeMismatch(expected: T.self, actual: type(of: value))
            }
            return element
        }
    }
    
    public func idMap<T: Object>(forKey key: KeyType) throws -> [T] {
        guard let ids = try self.any(for: key) as? [Any?] else {
            return []
        }
        return ids.compactMap({ id in
            guard let objID = id else {
                return nil
            }
            return Realm.shared.object(ofType: T.self, forPrimaryKey: objID)
        })
    }
    
    public func idMap<T: Object>(forKey key: KeyType) throws -> T? {
        let id: Any? = try self.any(for: key)
        guard let objID = id else {
            return nil
        }
        return Realm.shared.object(ofType: T.self, forPrimaryKey: objID)
    }
    
    public func combinedDictionaryOfDictionariesOfArrays<T: ValueType>() throws -> [T] {
        guard let dictValue = self as? [String : Any], dictValue is [String : [[String : Any]]] else {
            throw MarshalError.typeMismatchWithKey(key: "self", expected: [AnyHashable : Any].self, actual: self.self)
        }
        
        var transformed: [[String : Any]] = []
        
        for obj in (dictValue as! [String : [[String : Any]]]) {
            for var subObj in obj.value {
                subObj[JSONParser.dictionaryKey] = obj.key
                transformed.append(subObj)
            }
        }
        
        return try transformed.map {
            let value = try T.value(from: $0)
            guard let element = value as? T else {
                throw MarshalError.typeMismatch(expected: T.self, actual: type(of: value))
            }
            return element
        }
    }
    
    public func combinedDictionaryOfDictionaries<T: ValueType>() throws -> [T] {
        guard let dict = self as? [String : [String : Any]] else {
            throw MarshalError.typeMismatch(expected: [String : [String : Any]].self, actual: self.self)
        }
        
        var transformed: [[String : Any]] = []
        for kv in dict {
            var subObj = kv.value
            subObj[JSONParser.dictionaryKey] = kv.key
            transformed.append(subObj)
        }
        
        return try transformed.map {
            let value = try T.value(from: $0)
            guard let element = value as? T else {
                throw MarshalError.typeMismatch(expected: T.self, actual: type(of: value))
            }
            return element
        }
    }
    
    public func combinedDictionaryOfDictionaries<T: ValueType>(for key: KeyType) throws -> [T] {
        guard let dict: [String : Any] = try self.value(for: key), let dictValue = dict as? [String : [String : Any]] else {
            if self.optionalAny(for: key) != nil {
                throw MarshalError.typeMismatch(expected: [String : [String : Any]].self, actual: self.self)
            } else { // If there is no such key, we shouldn't throw an error
                return []
            }
        }
        
        var transformed: [[String : Any]] = []
        for kv in dictValue {
            var subObj = kv.value
            subObj[JSONParser.dictionaryKey] = kv.key
            transformed.append(subObj)
        }
        
        return try transformed.map {
            let value = try T.value(from: $0)
            guard let element = value as? T else {
                throw MarshalError.typeMismatch(expected: T.self, actual: type(of: value))
            }
            return element
        }
    }
}

extension Dictionary {
    public func dictionaryTransformedValues<T: ValueType>(for key: KeyType) throws -> [T] {
        guard let dictValue: [String : Any] = try self.value(for: key) else {
            if self.optionalAny(for: key) != nil {
                throw MarshalError.typeMismatchWithKey(key: key.stringValue, expected: [AnyHashable : Any].self, actual: self.self)
            } else { // If there is no such key, we shouldn't throw an error
                return []
            }
        }
        
        return try dictValue.transformDictionaryValues()
    }
    
    public func transformDictionaryValues<T: ValueType>() throws -> [T] {
        let transformed = self.map({[JSONParser.dictionaryKey: $0, JSONParser.dictionaryValue: $1]})
        
        return try transformed.map {
            let value = try T.value(from: $0)
            guard let element = value as? T else {
                throw MarshalError.typeMismatch(expected: T.self, actual: type(of: value))
            }
            return element
        }
    }
    
    public func parseValue<T: ValueType>() throws -> T {
        let value = try T.value(from: self)
        guard let obj = value as? T else {
            throw MarshalError.typeMismatch(expected: T.self, actual: type(of: value))
        }
        return obj
    }
    
    public func parseValue<T: ValueType>() throws -> T? {
        let value = try T.value(from: self)
        guard let obj = value as? T else {
            return nil
        }
        return obj
    }
}

extension Array {
    public func parseValues<T: ValueType>() throws -> [T] {
        return try self.map {
            let value = try T.value(from: $0)
            guard let element = value as? T else {
                throw MarshalError.typeMismatch(expected: T.self, actual: type(of: value))
            }
            return element
        }
    }
    
    public func parseFlatValues<T: ValueType>() throws -> [T] {
        return try self.compactMap {
            let value = try T.value(from: $0)
            guard let element = value as? T else {
                return nil
            }
            return element
        }
    }
    
    public func parseValues<T: ValueType>() throws -> [T?] {
        return try self.map {
            let value = try T.value(from: $0)
            guard let element = value as? T else {
                return nil
            }
            return element
        }
    }
}

