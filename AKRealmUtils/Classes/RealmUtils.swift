//
//  RealmUtils.swift
//  AKRealmUtils
//
//  Created by Artem Kalmykov on 10/17/17.
//

import Foundation
import RealmSwift
import Marshal

public protocol Disposable {
    func disposable() -> Bool
    
    /// Is guaranteed to be called in a write transaction
    func willDispose()
}

public extension Disposable {
    func willDispose() {}
}

extension Realm {
    private static var sharedRealm: Realm = {
        do {
            return try Realm()
        } catch let error {
            print("Realm initialization error: " + error.localizedDescription)
            exit(0)
        }
    }()
    
    public class var shared: Realm {
        return self.sharedRealm
    }
    
    public func finishWrite() {
        do {
            try self.commitWrite()
        } catch let error {
            print("Realm write error: " + error.localizedDescription)
        }
    }
    
    public func safeWrite(_ block: (() -> Void)) {
        if self.isInWriteTransaction {
            block()
        } else {
            do {
                try self.write(block)
            } catch let error {
                print("Realm write error: " + error.localizedDescription)
            }
        }
    }
    
    public static var autoCleanUp = true
    public private(set) static var disposableEntities: [Object.Type] = []
    
    public class func addDisposableType<T: Object>(_ type: T.Type) where T: Disposable {
        self.disposableEntities.append(type)
    }
    
    public func cleanUp() {
        self.beginWrite()
        for type in Realm.disposableEntities {
            self.objects(type).filter({($0 as! Disposable).disposable()}).forEach({
                ($0 as! Disposable).willDispose()
                $0.deleteFromRealm()
            })
        }
        self.finishWrite()
    }
}

extension Object {
    public func addToRealm(update: Bool = true) {
        Realm.shared.add(self, update: update)
    }
    
    public func deleteFromRealm() {
        Realm.shared.delete(self)
    }
    
    public class func parseObject<T: ValueType>(_ rawObject: Any?) -> T? {
        guard let rawObject = rawObject as? JSONObject else {
            return nil
        }
        
        do {
            Realm.shared.beginWrite()
            let value: T? = try rawObject.parseValue()
            Realm.shared.finishWrite()
            Realm.shared.cleanUp()
            return value
        } catch let error {
            Realm.shared.cancelWrite()
            self.handleError(error)
            return nil
        }
    }
    
    public class func parseObject<T: ValueType>(_ rawObject: Any?) throws -> T {
        guard let rawObject = rawObject as? JSONObject else {
            throw MarshalError.typeMismatch(expected: T.self, actual: Any.self)
        }
        
        do {
            Realm.shared.beginWrite()
            let value: T = try rawObject.parseValue()
            Realm.shared.finishWrite()
            Realm.shared.cleanUp()
            return value
        } catch {
            Realm.shared.cancelWrite()
            throw MarshalError.typeMismatch(expected: T.self, actual: Any.self)
        }
    }
    
    public class func parseObjects<T: ValueType>(_ rawObjects: Any?) -> [T] {
        guard let rawObjects = rawObjects as? [JSONObject] else {
            return []
        }
        
        do {
            Realm.shared.beginWrite()
            let values: [T] = try rawObjects.parseValues()
            Realm.shared.finishWrite()
            Realm.shared.cleanUp()
            return values
        } catch let error {
            Realm.shared.cancelWrite()
            self.handleError(error)
            return []
        }
    }
    
    private class func handleError(_ error: Error) {
        if let marshalError = error as? MarshalError {
            print("Marshal parsing error: " + marshalError.description)
        } else {
            print("Unknown parsing error: " + error.localizedDescription)
        }
    }
}
