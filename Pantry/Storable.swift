//
//  Storable.swift
//  Storable
//
//  Created by Nick O'Neill on 10/29/15.
//  Copyright © 2015 That Thing in Swift. All rights reserved.
//

import Foundation

/**
 ## Storable protocol

 The struct should conform to this protocol.

 ### sample
 ```swift
 struct Basic: Storable {
    let name: String
    let age: Float
    let number: Int

    init(warehouse: JSONWarehouse) {
        self.name = warehouse.get("name") ?? "default"
        self.age = warehouse.get("age") ?? 20.5
        self.number = warehouse.get("number") ?? 10
    }
 }
 ```
 */
public protocol Storable {
    /** 
     Struct initialization  

     - parameter warehouse: the `Warehouseable` object from which you can extract your struct's properties
     */
    init(warehouse: Warehouseable)

    /**
     Dictionary representation  

     Returns the dictioanry representation of the current struct
     - returns: [String: AnyObject]
     */
    func toDictionary() -> [String: AnyObject]
}

public extension Storable {
    /**
     Dictionary representation
     Returns the dictioanry representation of the current struct
     
     _Adapted from [@IanKeen](https://gist.github.com/IanKeen/3a6c3b9a42aaf9fea982)_
     - returns: [String: AnyObject]
     */
    func toDictionary() -> [String: AnyObject] {
        let mirror = Mirror(reflecting: self)
        return mirror.children.reduce([:]) { result, child in
            guard let key = child.label else { return result }
            var actualValue = child.value
            var childMirror = Mirror(reflecting: child.value)
            if let style = childMirror.displayStyle where style == .Optional && childMirror.children.count > 0 {
                // unwrap Optional type first
                actualValue = childMirror.children.first!.value
                childMirror = Mirror(reflecting: childMirror.children.first!.value)
            }
            
            if let style = childMirror.displayStyle where style == .Collection {
                // collections need to be unwrapped, children tested and
                // toDictionary called on each
                let converted: [AnyObject] = childMirror.children
                    .filter { $0.value is Storable || $0.value is AnyObject }
                    .map { collectionChild in
                        if let convertable = collectionChild.value as? Storable {
                            return convertable.toDictionary()
                        } else {
                            return collectionChild.value as! AnyObject
                        }
                    }
                return combine(result, addition: [key: converted])
                
            } else {
                // non-collection types, toDictionary or just cast default types
                if let value = actualValue as? Storable {
                    return combine(result, addition: [key: value.toDictionary()])
                } else if let value = actualValue as? AnyObject {
                    return combine(result, addition: [key: value])
                } else {
                    // throw an error? not a type we support
                }
            }
            
            return result
        }
    }
    
    // convenience for combining dictionaries
    private func combine(from: [String: AnyObject], addition: [String: AnyObject]) -> [String: AnyObject] {
        var result = [String: AnyObject]()
        [from, addition].forEach { dict in
            dict.forEach { result[$0.0] = $0.1 }
        }
        return result
    }
}

/**
 Storage expiry
 */
public enum StorageExpiry {
    /// the storage never expires
    case Never
    /// the storage expires after a given timeout in seconds (`NSTimeInterval`)
    case Seconds(NSTimeInterval)
    /// the storage expires at a given date (`NSDate`)
    case Date(NSDate)

    /**
     Expiry date

     Returns the date of the storage expiration
     - returns NSDate
     */
    func toDate() -> NSDate {
        switch self {
        case Never:
            return NSDate.distantFuture()
        case Seconds(let timeInterval):
            return NSDate(timeIntervalSinceNow: timeInterval)
        case Date(let date):
            return date
        }
    }
}

// MARK: default types that are supported

/**
Default storable types

Default types are `Bool`, `String`, `Int`, `Float`
*/
public protocol StorableDefaultType {
}

extension Bool: StorableDefaultType { }
extension String: StorableDefaultType { }
extension Int: StorableDefaultType { }
extension Float: StorableDefaultType { }
