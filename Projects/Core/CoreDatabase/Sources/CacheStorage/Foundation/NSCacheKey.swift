//
//  NSCacheKey.swift
//  SoongBook
//
//  Created by 이숭인 on 11/27/24.
//

import Foundation

public final class NSCacheKey<T: CacheKeyable>: NSObject {
    public let value: T
    
    public init(value: T) {
        self.value = value
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? NSCacheKey else { return false }
        return self.value == other.value
    }
    
    public override var hash: Int {
        return value.hashValue ^ 0x9e3779b9
    }
}
