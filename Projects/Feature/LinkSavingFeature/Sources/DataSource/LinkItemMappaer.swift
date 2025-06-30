//
//  LinkItemMappaer.swift
//  LinkSavingInterface
//
//  Created by 이숭인 on 5/25/25.
//

import Foundation
import CoreDatabase
import LinkSavingInterface

final class LinkItemMappaer {
    static func from(dto: LinkItemDTO) -> LinkItem {
        LinkItem(
            identifier: dto.identifier,
            url: dto.url,
            title: dto.title,
            content: dto.content,
            thumbnailImageURL: dto.thumbnailImageURL,
            memoContent: dto.memoContent,
            categoryIdentifier: dto.categoryIdentifier,
            timestamp: dto.timestamp
        )
    }
    
    static func toDTO(domain: LinkItem) -> LinkItemDTO {
        LinkItemDTO(
            identifier: domain.identifier,
            url: domain.url,
            title: domain.title,
            content: domain.content,
            thumbnailImageURL: domain.thumbnailImageURL,
            memoContent: domain.memoContent,
            categoryIdentifier: domain.categoryIdentifier,
            timestamp: domain.timestamp
        )
    }
}
