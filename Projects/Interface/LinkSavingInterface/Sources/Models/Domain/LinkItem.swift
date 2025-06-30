//
//  LinkItem.swift
//  LinkSavingInterface
//
//  Created by 이숭인 on 5/25/25.
//

import Foundation

public struct LinkItem {
    public let identifier: String
    public let url: String
    public var title: String
    public var content: String?
    public let thumbnailImageURL: String?
    public var memoContent: String
    public var categoryIdentifier: String
    public var timestamp: Date
    
    public init(
        identifier: String,
        url: String,
        title: String,
        content: String?,
        thumbnailImageURL: String?,
        memoContent: String,
        categoryIdentifier: String,
        timestamp: Date
    ) {
        self.identifier = identifier
        self.url = url
        self.title = title
        self.content = content
        self.thumbnailImageURL = thumbnailImageURL
        self.memoContent = memoContent
        self.categoryIdentifier = categoryIdentifier
        self.timestamp = timestamp
    }
}

public enum LinkItemError: Error, LocalizedError {
    case unknown
    case notFound
    
    case addFailed
    case batchAddFailed
    
    case fetchFailed
    case batchFetchFailed
    
    case updateFailed
    case noRecordToUpdate
    case batchUpdateFailed
    
    case deleteFailed
    case noRecordToDelete
    case batchDeleteFailed
    case deleteAllFailed
    
    case observationFailed(Error)
    case realmCreationFailed(Error)
}
