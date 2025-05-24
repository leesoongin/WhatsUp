//
//  DatabaseBuilder+Extension.swift
//  CoreFoundationKit
//
//  Created by 이숭인 on 5/24/25.
//

import Foundation
import RealmSwift
import Combine

// MARK: - Default Configuration
public extension DatabaseBuilder {
    var realmConfiguration: Realm.Configuration {
        return Realm.Configuration.defaultConfiguration
    }
    
    var migrations: [DatabaseMigration] {
        return []
    }
    
    var concurrentQueue: DispatchQueue {
        return DispatchQueue(
            label: "database.concurrent.queue.\(Entity.self)",
            qos: .userInitiated,
            attributes: .concurrent
        )
    }
    
    var serialQueue: DispatchQueue {
        return DispatchQueue(
            label: "database.serial.queue.\(Entity.self)",
            qos: .userInitiated
        )
    }
}

// MARK: - Internal Operations
public extension DatabaseBuilder {
    func createRealm() throws -> Realm {
        return try Realm(configuration: realmConfiguration)
    }
    
    func createDetachedCopy(of entity: Entity) -> Entity {
        let detachedEntity = Entity()
        
        let mirror = Mirror(reflecting: entity)
        for child in mirror.children {
            guard let propertyName = child.label else { continue }
            
            // Realm의 managed 프로퍼티는 복사하지 않음
            if propertyName.hasPrefix("realm") || propertyName.hasPrefix("invalidated") {
                continue
            }
            
            detachedEntity.setValue(child.value, forKey: propertyName)
        }
        
        return detachedEntity
    }
    
    func createDetachedCopies(of entities: [Entity]) -> [Entity] {
        return entities.map { createDetachedCopy(of: $0) }
    }
    
    func performRead<T>(_ block: @escaping (Realm) throws -> T) -> AnyPublisher<T, DatabaseError> {
        return Future<T, DatabaseError> { promise in
            self.concurrentQueue.async {
                autoreleasepool {
                    do {
                        let realm = try self.createRealm()
                        let result = try block(realm)
                        promise(.success(result))
                    } catch {
                        promise(.failure(.queryFailed(error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func performWrite<T>(_ block: @escaping (Realm) throws -> T) -> AnyPublisher<T, DatabaseError> {
        return Future<T, DatabaseError> { promise in
            self.serialQueue.async {
                autoreleasepool {
                    do {
                        let realm = try self.createRealm()
                        let result = try realm.write {
                            return try block(realm)
                        }
                        promise(.success(result))
                    } catch {
                        promise(.failure(.saveFailed(error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func asyncPerformRead<T>(_ block: @escaping (Realm) throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            concurrentQueue.async {
                autoreleasepool {
                    do {
                        let realm = try self.createRealm()
                        let result = try block(realm)
                        continuation.resume(returning: result)
                    } catch {
                        continuation.resume(throwing: DatabaseError.queryFailed(error))
                    }
                }
            }
        }
    }
    
    func asyncPerformWrite<T>(_ block: @escaping (Realm) throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            serialQueue.async {
                autoreleasepool {
                    do {
                        let realm = try self.createRealm()
                        let result = try realm.write {
                            return try block(realm)
                        }
                        continuation.resume(returning: result)
                    } catch {
                        continuation.resume(throwing: DatabaseError.saveFailed(error))
                    }
                }
            }
        }
    }
    
    // MARK: Batch Operations
    func batchCreate(_ entities: [Entity]) -> AnyPublisher<[Entity], DatabaseError> {
        let entitiesToSave = entities.map { entity in
            entity.realm != nil ? createDetachedCopy(of: entity) : entity
        }
        
        return performWrite { realm in
            realm.add(entitiesToSave, update: .modified)
            return entitiesToSave
        }
        .map { [self] savedEntities in
            createDetachedCopies(of: savedEntities)
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    func batchDelete(_ primaryKeys: [Entity.PrimaryKeyType]) -> AnyPublisher<Void, DatabaseError> {
        return performWrite { realm in
            for primaryKey in primaryKeys {
                if let entity = realm.object(ofType: Entity.self, forPrimaryKey: primaryKey) {
                    realm.delete(entity)
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    func asyncBatchCreate(_ entities: [Entity]) async throws -> [Entity] {
        let entitiesToSave = entities.map { entity in
            entity.realm != nil ? createDetachedCopy(of: entity) : entity
        }
        
        let savedEntities = try await asyncPerformWrite { realm in
            realm.add(entitiesToSave, update: .modified)
            return entitiesToSave
        }
        
        return createDetachedCopies(of: savedEntities)
    }
    
    func asyncBatchDelete(_ primaryKeys: [Entity.PrimaryKeyType]) async throws {
        try await asyncPerformWrite { realm in
            for primaryKey in primaryKeys {
                if let entity = realm.object(ofType: Entity.self, forPrimaryKey: primaryKey) {
                    realm.delete(entity)
                }
            }
        }
    }
}
