//
//  LinkItemDTO.swift
//  LinkSavingFeature
//
//  Created by 이숭인 on 5/24/25.
//

import Foundation
import RealmSwift
import CoreDatabase

class LinkItemDTO: Object, DatabaseEntity {
    @Persisted(primaryKey: true) var identifier: String
    @Persisted var url: String
    @Persisted var title: String
    @Persisted var content: String?
    @Persisted var thumbnailImageURL: String?
    @Persisted var memoContent: String
    @Persisted var categoryIdentifier: String
    @Persisted var timestamp: Date
    
    var compositeKey: String {
        return identifier
    }
    
    override init() {
         super.init()
     }
    
    convenience init(
        identifier: String,
        url: String,
        title: String,
        content: String?,
        thumbnailImageURL: String?,
        memoContent: String,
        categoryIdentifier: String,
        timestamp: Date
    ) {
        self.init()
        
        self.identifier = identifier
        self.url = url
        self.title = title
        self.content = content
        self.thumbnailImageURL = thumbnailImageURL
        self.memoContent = memoContent
        self.categoryIdentifier = categoryIdentifier
        self.timestamp = timestamp
    }
    
    func detached() -> LinkItemDTO {
        LinkItemDTO(
            identifier: self.identifier,
            url: self.url,
            title: self.title,
            content: self.content,
            thumbnailImageURL: self.thumbnailImageURL ?? "",
            memoContent: self.memoContent,
            categoryIdentifier: self.categoryIdentifier,
            timestamp: self.timestamp
        )
    }
}
