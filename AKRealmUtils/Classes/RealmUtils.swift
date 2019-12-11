//
//  RealmUtils.swift
//  AKRealmUtils
//
//  Created by Artem Kalmykov on 10/17/17.
//

import Foundation
import RealmSwift

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
    
    public static func encrypt(withKey key: Data) {
    }
    
    public static var shared: Realm {
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
    
    public static func addDisposableType<T: Object>(_ type: T.Type) where T: Disposable {
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
    public func addToRealm(update: Realm.UpdatePolicy = .error) {
        Realm.shared.add(self, update: update)
    }
    
    @objc open func deleteFromRealm() {
        Realm.shared.delete(self)
    }
}
