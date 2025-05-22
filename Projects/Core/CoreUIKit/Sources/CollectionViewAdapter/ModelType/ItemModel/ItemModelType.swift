//
//  ItemModelType.swift
//  AlamofirePractice
//
//  Created by 이숭인 on 6/13/24.
//

import Foundation

public protocol ItemModelType: ModelType {
    var viewType: ViewType { get }
    
    var widthStrategy: ViewWidthStrategy { get }
    var heightStrategy: ViewHeightStrategy { get }
}

extension ItemModelType {
    // swiftlint:disable:next legacy_hashing
    public var hashValue: Int {
        var hasher = Hasher()
        innerHash(into: &hasher)
        return hasher.finalize()
    }
    
    /// 셀의 변경을 알리기 위함. Cell refresh 의 트리거
    func innerHash(into hasher: inout Hasher) {
        hasher.combine(identifier)
        hasher.combine(viewType.getIdentifier())
        hasher.combine(widthStrategy)
        hasher.combine(heightStrategy)
        
        hash(into: &hasher)
    }
    
    public var sizeHashValue: Int {
        var hasher = Hasher()
        sizeInnerHash(into: &hasher)
        return hasher.finalize()
    }
    
    /// 사이즈의 변경을 알리기 위함. Cached Cell Size Refresh 의 트리거
    func sizeInnerHash(into hasher: inout Hasher) {
        hasher.combine(viewType.getIdentifier())
        hasher.combine(widthStrategy)
        hasher.combine(heightStrategy)
        
        sizeHash(into: &hasher)
    }
}

public enum ViewType {
    case type(ItemModelBindable.Type)
    
    func getClass() -> AnyClass {
        guard case let .type(type) = self else { fatalError() }
        return type
    }
    
    func getIdentifier() -> String {
        guard case let .type(type) = self else { fatalError() }
        return String(describing: type)
    }
}

public enum ViewStrategy {
    case `static`(size: CGFloat)
    case ratio(value: CGFloat)
    case adaptive
}

/// CollectionViewCell의 가로 크기 정책
public enum ViewWidthStrategy: Hashable {
    /// 단순값
    case `static`(CGFloat)
    /// collectionView 가로 크기만큼
    case fill
    /// collectionView column 개수
    case column(Int)
    /// collectionView 가로 크기 * 비율만큼
    case ratioWithCollectionView(CGFloat)
    /// Cell의 크기에 따라
    case adaptive
}

/// CollectionViewCell의 세로 크기 정책
public enum ViewHeightStrategy: Hashable {
    /// 단순값
    case `static`(CGFloat)
    /// alignment 크기 * 비율만큼
    case ratio(CGFloat)
    /// collectionView 세로 크기 * 비율만큼
    case ratioWithCollectionView(CGFloat)
    /// Cell의 크기에 따라
    case adaptive
}

