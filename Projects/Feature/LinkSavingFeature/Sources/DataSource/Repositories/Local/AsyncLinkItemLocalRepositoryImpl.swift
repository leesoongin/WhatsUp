//
//  AsyncLinkItemLocalRepositoryImpl.swift
//  LinkSavingFeature
//
//  Created by 이숭인 on 6/14/25.
//

import Foundation
import Combine
import CoreDatabase
import CoreFoundationKit
import LinkSavingInterface

actor LinkItemAsyncDatabaseBuilder: AsyncDatabaseBuilder {
    typealias Entity = LinkItemDTO
}

final class AsyncLinkItemLocalRepositoryImpl {
    private var cancellables = Set<AnyCancellable>()
    
    private let asyncDatabaseBuilder: LinkItemAsyncDatabaseBuilder
    
    init(asyncDatabaseBuilder: LinkItemAsyncDatabaseBuilder) {
        self.asyncDatabaseBuilder = asyncDatabaseBuilder
    }
    
    func add(with item: LinkItem) async throws -> LinkItem {
        let dtoModel = LinkItemMappaer.toDTO(domain: item)
        
        _ = try await asyncDatabaseBuilder.create(dtoModel)
        
        return LinkItemMappaer.from(dto: dtoModel)
    }
    
    func read(with primaryKey: String) async throws -> LinkItem {
        let item = try await asyncDatabaseBuilder.read(primaryKey: primaryKey)
        return LinkItemMappaer.from(dto: item)
    }
    
    func readAll() async throws -> [LinkItem] {
        let items = try await asyncDatabaseBuilder.readAll()
        return items.map { LinkItemMappaer.from(dto: $0) }
    }
    
    func delete(with primaryKey: String) async throws {
        try await asyncDatabaseBuilder.delete(primaryKey: primaryKey)
    }
    
    func deleteAll() async throws {
        try await asyncDatabaseBuilder.deleteAll()
    }
    
    func exists(with primaryKey: String) async throws -> Bool {
        return try await asyncDatabaseBuilder.exists(primaryKey: primaryKey)
    }
    
    func count() async throws -> Int {
        return try await asyncDatabaseBuilder.count()
    }
    
    func query(_ predicate: NSPredicate) async throws -> [LinkItem] {
        let dtos = try await asyncDatabaseBuilder.query(predicate)
        return dtos.map { LinkItemMappaer.from(dto: $0) }
    }
}
