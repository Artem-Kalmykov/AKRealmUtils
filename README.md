# AKRealmUtils

[![CI Status](http://img.shields.io/travis/Artem-Kalmykov/AKRealmUtils.svg?style=flat)](https://travis-ci.org/ArKalmykov/AKRealmUtils)
[![Version](https://img.shields.io/cocoapods/v/AKRealmUtils.svg?style=flat)](http://cocoapods.org/pods/AKRealmUtils)
[![License](https://img.shields.io/cocoapods/l/AKRealmUtils.svg?style=flat)](http://cocoapods.org/pods/AKRealmUtils)
[![Platform](https://img.shields.io/cocoapods/p/AKRealmUtils.svg?style=flat)](http://cocoapods.org/pods/AKRealmUtils)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

AKRealmUtils is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'AKRealmUtils'
```

## Usage

### Realm Utils

#### Realm.shared

```swift
extension Realm {
    public static var shared: Realm
}
```

`Realm.shared` returns realm instance as if it was instantiated with `Realm()`, but handles initialization errors. If any error happens, application quits.

#### Realm.shared.finishWrite()

```swift
extension Realm {
    public func finishWrite()
}
```

Is the same as `realm.commitWrite()` but with automatic error handling.

#### Realm.shared.safeWrite()

```swift
extension Realm {
    public func safeWrite(_ block: (() -> Void))
}
```

Is similar to `realm.write {}`, but may be called even while already in a write transaction.

#### Realm.Object.addToRealm()

```swift
extension Object {
    public func addToRealm(update: Bool = true)
}
```

Is the same as calling `Realm.shared.add(object, update)`. Update is true by default, will result in error if Object doesn't have a primary key.

#### Realm.Object.deleteFromRealm()

```swift
extension Object {
    public func deleteFromRealm()
}
```

Is the same as calling `Realm.shared.delete(object)`.

#### Realm.Object.parse

```swift
extension Object {
    public class func parseObject<T: ValueType>(_ rawObject: Any?) -> T?
    public class func parseObject<T: ValueType>(_ rawObject: Any?) throws -> T
    public class func parseObjects<T: ValueType>(_ rawObjects: Any?) -> [T]
}
```

Each of this methods open a write transaction, parse objects as realm objects, close write transaction and handle errors. Is very useful when parsing server's response. Also, bypasses Marshal limitation, which doesn't allow to parse top level object or array.

#### Realm clean up

In some approaches some Realm objects have to be deleted after parsing. Mark objects which have to be cleaned up with `Disposable` protocol:

```swift
public protocol Disposable {
    func disposable() -> Bool

    /// Is guaranteed to be called in a write transaction
    func willDispose()
}
```

`willDispose()` is optional.

Then disposable properties should be added to Realm with the following method:

```swift
extension Realm {
    public class func addDisposableType<T: Object>(_ type: T.Type) where T: Disposable
}
```

Clean up may be done either automatically (when one of `Object.parse`  methods is called) or manually:

```swift
extension Realm {
    public static var autoCleanUp = true
    public func cleanUp()
}
```

### Marshal utils

#### Transforming dictionary to array.

This could be invoked from:

```swift
extension MarshaledObject {
    public func dictionaryTransformedValues<T: ValueType>(for key: KeyType) throws -> [T]
    public func transformDictionaryValues<T: ValueType>() throws -> [T]
}

extension Dictionary {
    public func dictionaryTransformedValues<T: ValueType>(for key: KeyType) throws -> [T]
    public func transformDictionaryValues<T: ValueType>() throws -> [T]
}
```

Call `for key` methods if dictionary is located under a specific key in another dictionary. No argument methods perform transformation on the object itself.

E.g. we have the following dictionary:

```json
{
    "id1": 1,
    "id2": 3,
    "id0": "asd"
}
```

Calling transform on this will result in the following array:

```json
[
    {
        "_Marshal_DictionaryKey": "id1",
        "_Marshal_DictionaryValue": 1
    },
    {
        "_Marshal_DictionaryKey": "id2",
        "_Marshal_DictionaryValue": 3
    },
    {
        "_Marshal_DictionaryKey": "id0",
        "_Marshal_DictionaryValue": asd
    },
]
```

Accessing dictionary entries may be done in two ways:

```swift
extension MarshaledObject {
    public func valueForDictionaryKey<T: ValueType>() throws -> T
    public func valueForDictionaryValue<T: ValueType>() throws -> T
    public func valueForDictionaryKey<T: ValueType>() throws -> [T]
    public func valueForDictionaryValue<T: ValueType>() throws -> [T]
}
```

or by directly fetching values by keys. Keys are constants declared in:

```swift
extension JSONParser {
    public static var dictionaryKey: String {
        return "_Marshal_DictionaryKey"
    }

    public static var dictionaryValue: String {
        return "_Marshal_DictionaryValue"
    }
}
```

#### Transforming dictionaries of arrays of dictionaries to array

This is useful in the case we have the following structure:

```json
{
    "id1":
    [
        {
            "key1": "value1",
            "key2": "value2"
        },
        {
            "key3": "value3",
            "key4": "value4"
        },
        
    ],
    "id2":
    [
        {
            "key5": "value5",
            "key6": "value6"
        },
        {
            "key7": "value7",
            "key8": "value8"
        },
    ]
}
```

and we want to receive:

```json
[
    {
        "key1": "value1",
        "key2": "value2",
        "_Marshal_DictionaryKey": "id1"
    },
    {
        "key3": "value3",
        "key4": "value4",
        "_Marshal_DictionaryKey": "id1"
    },
    {
        "key5": "value5",
        "key6": "value6",
        "_Marshal_DictionaryKey": "id2"
    },
    {
        "key7": "value7",
        "key8": "value8",
        "_Marshal_DictionaryKey": "id2"
    },
]
```

Methods:

```swift
extension MarshaledObject {
    public func combinedDictionaryOfDictionariesOfArrays<T: ValueType>(for key: KeyType) throws -> [T]
    public func combinedDictionaryOfDictionariesOfArrays<T: ValueType>() throws -> [T]
}
```

#### Transforming dictionary of dictionaries to array

E.g. we have the following structure:

```json
{
    "id1":
    {
        "key1": "value1",
        "key2": "value2"
    },
    "id2":
    {
        "key3": "value3",
        "key4": "value4"
    },
}
```

and we want to receive:

```json
[
    {
        "key1": "value1",
        "key2": "value2",
        "_Marshal_DictionaryKey": "id1"
    },
    {
        "key3": "value3",
        "key4": "value4",
        "_Marshal_DictionaryKey": "id2"
    }
]
```

Methods:

```swift
extension MarshaledObject {
    public func combinedDictionaryOfDictionaries<T: ValueType>() throws -> [T]
    public func combinedDictionaryOfDictionaries<T: ValueType>(for key: KeyType) throws -> [T]
}
```

#### ID Mapping

In case if we receive object ID (or IDs), but we want to store a relationship to that object, we may use:

```swift
extension MarshaledObject {
    public func idMap<T: Object>(forKey key: KeyType) throws -> [T]
    public func idMap<T: Object>(forKey key: KeyType) throws -> T?
}
```

It will automatically get ID(s), which is(are) stored under `key`, fetch that object(s) from Realm and return it.

## Author

Artem-Kalmykov, ar.kalmykov@yahoo.com

## License

AKRealmUtils is available under the MIT license. See the LICENSE file for more info.
