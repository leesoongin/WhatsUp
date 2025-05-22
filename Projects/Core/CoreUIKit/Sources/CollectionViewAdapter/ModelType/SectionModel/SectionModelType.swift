//
//  SectionModelType.swift
//  AlamofirePractice
//
//  Created by 이숭인 on 6/13/24.
//

import UIKit

public protocol SectionModelType: ModelType {
    var collectionLayout: CompositionalLayoutModelType? { get }
    
    var header: ItemModelType? { get }
    var footer: ItemModelType? { get }

    var itemModels: [ItemModelType] { get }
}

extension SectionModelType {
    public var hashValue: Int {
        var hasher = Hasher()
        innerHash(into: &hasher)
        return hasher.finalize()
    }
    
    func innerHash(into hasher: inout Hasher) {
        hasher.combine(identifier)
        header?.innerHash(into: &hasher)
        footer?.innerHash(into: &hasher)
        
        hash(into: &hasher)
    }
    
    public var sizeHashValue: Int {
        var hasher = Hasher()
        innerSizeHash(into: &hasher)
        return hasher.finalize()
    }
    
    func innerSizeHash(into hasher: inout Hasher) {
        sizeHash(into: &hasher)
    }
}
