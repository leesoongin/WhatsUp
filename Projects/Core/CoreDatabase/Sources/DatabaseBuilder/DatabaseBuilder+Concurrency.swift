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
        let entityToSave = entity.realm != nil ? createDetachedCopy(of: entity) : entity
        
        let savedEntity = try await asyncPerformWrite { realm in
            realm.add(entityToSave, update: .modified)
            return entityToSave
        }
        
        return createDetachedCopy(of: savedEntity)
    }
    
    func asyncRead(primaryKey: Entity.PrimaryKeyType) async throws -> Entity? {
        let entity = try await asyncPerformRead { realm in
            return realm.object(ofType: Entity.self, forPrimaryKey: primaryKey)
        }
        
        return entity.map { createDetachedCopy(of: $0) }
    }
    
    func asyncReadAll() async throws -> [Entity] {
        let entities = try await asyncPerformRead { realm in
            return Array(realm.objects(Entity.self))
        }
        
        return createDetachedCopies(of: entities)
    }
    
    func asyncUpdate(_ entity: Entity) async throws -> Entity {
        return try await asyncCreate(entity) // Realm의 upsert 특성 활용
    }
    
    func asyncDelete(primaryKey: Entity.PrimaryKeyType) async throws {
        try await asyncPerformWrite { realm in
            guard let entity = realm.object(ofType: Entity.self, forPrimaryKey: primaryKey) else {
                throw DatabaseError.entityNotFound
            }
            realm.delete(entity)
        }
    }
    
    func asyncDeleteAll() async throws {
        try await asyncPerformWrite { realm in
            let entities = realm.objects(Entity.self)
            realm.delete(entities)
        }
    }
    
    func asyncQuery(_ predicate: NSPredicate) async throws -> [Entity] {
        let entities = try await asyncPerformRead { realm in
            return Array(realm.objects(Entity.self).filter(predicate))
        }
        
        return createDetachedCopies(of: entities)
    }
    
    func asyncCount() async throws -> Int {
        return try await asyncPerformRead { realm in
            return realm.objects(Entity.self).count
        }
    }
    
    func asyncExists(primaryKey: Entity.PrimaryKeyType) async throws -> Bool {
        return try await asyncPerformRead { realm in
            return realm.object(ofType: Entity.self, forPrimaryKey: primaryKey) != nil
        }
    }

}
