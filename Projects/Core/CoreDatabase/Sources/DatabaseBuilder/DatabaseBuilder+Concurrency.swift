//
//  DatabaseBuilder+Concurrency.swift
//  CoreFoundationKit
//
//  Created by 이숭인 on 5/24/25.
//

import Foundation
import Combine
import RealmSwift

// MARK: - Async/Await CRUD Operations
public extension DatabaseBuilder {
    func asyncCreate(_ entity: Entity) async throws -> Entity {
        return try await asyncPerformWrite(entity)
    }
    
    func asyncRead(primaryKey: Entity.PrimaryKeyType) async throws -> Entity? {
        return try await asyncPerformRead(primaryKey: primaryKey)
    }
    
    func asyncReadAll() async throws -> [Entity] {
        return try await asyncReadAll()
    }
    
    func asyncUpdate(_ entity: Entity) async throws -> Entity {
        return try await asyncCreate(entity) // Realm의 upsert 특성 활용
    }
    
    func asyncDelete(primaryKey: Entity.PrimaryKeyType) async throws -> Void {
        try await asyncPerformDelete(primaryKey: primaryKey)
    }
    
    func asyncDeleteAll() async throws -> Void {
        try await asyncDeleteAll()
    }
    
    func asyncQuery(_ predicate: NSPredicate) async throws -> [Entity] {
        try await asyncPerformRead(with: predicate)
    }
    
    func asyncCount() async throws -> Int {
        return try await asyncPerformReadAll().count
    }
    
    func asyncExists(primaryKey: Entity.PrimaryKeyType) async throws -> Bool {
        return try await asyncPerformRead(primaryKey: primaryKey) != nil
    }
}
