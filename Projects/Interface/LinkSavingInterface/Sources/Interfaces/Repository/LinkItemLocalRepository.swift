//
//  LinkItemLocalRepository.swift
//  LinkSavingInterface
//
//  Created by 이숭인 on 5/24/25.
//

import Foundation
import Combine
import CoreFoundationKit

public protocol LinkItemLocalRepository {
    func add(with item: LinkItem) -> AnyPublisher<LinkItem, LinkItemError>
    func loadAll() -> AnyPublisher<[LinkItem], LinkItemError>
    func read(with primaryKey: String) -> AnyPublisher<LinkItem, LinkItemError>
    func remove(with primaryKey: String) -> AnyPublisher<Void, LinkItemError>
    func removeAll() -> AnyPublisher<Void, LinkItemError>
}
