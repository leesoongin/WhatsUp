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
//        return Realm.Configuration.defaultConfiguration
        let config = Realm.Configuration(
            schemaVersion: 1, // 버전은 늘려도 되고 안 늘려도 됨 (어차피 삭제됨)
            deleteRealmIfMigrationNeeded: true
        )
        Realm.Configuration.defaultConfiguration = config
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
    
    func performRead(with primaryKey: Entity.PrimaryKeyType) -> AnyPublisher<Entity?, DatabaseError> {
        return Future<Entity?, DatabaseError> { promise in
            self.concurrentQueue.async {
                autoreleasepool {
                    do {
                        let realm = try self.createRealm()
                        realm.refresh()
                        
                        let result = realm.object(ofType: Entity.self, forPrimaryKey: primaryKey)
                        promise(.success(result))
                    } catch {
                        promise(.failure(.realmCreationFailed(error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func performQuery(with predicate: NSPredicate) -> AnyPublisher<[Entity], DatabaseError> {
        return Future<[Entity], DatabaseError> { promise in
            self.concurrentQueue.async {
                autoreleasepool {
                    do {
                        let realm = try self.createRealm()
                        realm.refresh()
                        
                        let result = Array(realm.objects(Entity.self).filter(predicate))
                        promise(.success(result))
                    } catch {
                        promise(.failure(.realmCreationFailed(error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func performReadAll() -> AnyPublisher<[Entity], DatabaseError> {
        return Future<[Entity], DatabaseError> { promise in
            self.serialQueue.async {
                autoreleasepool {
                    do {
                        let realm = try self.createRealm()
                        realm.refresh()
                        
                        let results = Array(realm.objects(Entity.self))
                        print("::: read all count > \(results.count)")
                        promise(.success(results))
                    } catch {
                        promise(.failure(.realmCreationFailed(error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func performWrite(entity: Entity) -> AnyPublisher<Entity, DatabaseError> {
        return Future<Entity, DatabaseError> { promise in
            self.serialQueue.async {
                autoreleasepool {
                    do {
                        let realm = try self.createRealm()
                        
                        do {
                            try realm.write {
                                realm.add(entity, update: .modified)
                            }
                            
                            promise(.success(entity))
                        } catch {
                            promise(.failure(.insertFailed))
                        }
                    } catch {
                        promise(.failure(.realmCreationFailed(error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func performDelete(_ primaryKey: Entity.PrimaryKeyType) -> AnyPublisher<Void, DatabaseError> {
        return Future<Void, DatabaseError> { promise in
            self.serialQueue.async {
                autoreleasepool {
                    do {
                        let realm = try self.createRealm()
                        
                        do {
                            try realm.write {
                                guard let entity = realm.object(
                                    ofType: Entity.self,
                                    forPrimaryKey: primaryKey
                                ) else {
                                    throw DatabaseError.noRecordToDelete
                                }
                                realm.delete(entity)
                            }
                            promise(.success(Void()))
                        } catch {
                            promise(.failure(.deleteFailed))
                        }
                    } catch {
                        promise(.failure(.realmCreationFailed(error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func performDeleteAll() -> AnyPublisher<Void, DatabaseError> {
        return Future<Void, DatabaseError> { promise in
            self.serialQueue.async {
                autoreleasepool {
                    do {
                        let realm = try self.createRealm()
                        do {
                            try realm.write {
                                let entities = realm.objects(Entity.self)
                                realm.delete(entities)
                            }
                            
                            promise(.success(Void()))
                        } catch {
                            promise(.failure(.deleteAllFailed))
                        }
                        
                    } catch {
                        promise(.failure(.realmCreationFailed(error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func asyncPerformRead(primaryKey: Entity.PrimaryKeyType) async throws -> Entity? {
        return try await withCheckedThrowingContinuation { continuation in
            concurrentQueue.async {
                autoreleasepool {
                    do {
                        let realm = try self.createRealm()
                        let result = realm.object(ofType: Entity.self, forPrimaryKey: primaryKey)
                        continuation.resume(returning: result)
                    } catch {
                        continuation.resume(throwing: DatabaseError.realmCreationFailed(error))
                    }
                }
            }
        }
    }
    
    
    func asyncPerformReadAll() async throws -> [Entity] {
        return try await withCheckedThrowingContinuation { continuation in
            concurrentQueue.async {
                autoreleasepool {
                    do {
                        let realm = try self.createRealm()
                        let result = Array(realm.objects(Entity.self))
                        continuation.resume(returning: result)
                    } catch {
                        continuation.resume(throwing: DatabaseError.realmCreationFailed(error))
                    }
                }
            }
        }
    }
    
    func asyncPerformRead(with predicate: NSPredicate) async throws -> [Entity] {
        return try await withCheckedThrowingContinuation { continuation in
            concurrentQueue.async {
                autoreleasepool {
                    do {
                        let realm = try self.createRealm()
                        
                        let result = Array(realm.objects(Entity.self).filter(predicate))
                        continuation.resume(returning: result)
                    } catch {
                        continuation.resume(throwing: DatabaseError.realmCreationFailed(error))
                    }
                }
            }
        }
    }
    
    func asyncPerformWrite(_ entity: Entity) async throws -> Entity {
        return try await withCheckedThrowingContinuation { continuation in
            serialQueue.async {
                autoreleasepool {
                    do {
                        let realm = try self.createRealm()
                        do {
                            try realm.write {
                                realm.add(entity, update: .modified)
                            }
                            continuation.resume(returning: entity)
                        } catch {
                            continuation.resume(throwing: DatabaseError.insertFailed)
                        }
                    } catch {
                        continuation.resume(throwing: DatabaseError.realmCreationFailed(error))
                    }
                }
            }
        }
    }
    
    func asyncPerformDelete(primaryKey: Entity.PrimaryKeyType) async throws -> Void {
        return try await withCheckedThrowingContinuation { continuation in
            serialQueue.async {
                autoreleasepool {
                    do {
                        let realm = try self.createRealm()
                        do {
                            try realm.write {
                                guard let result = realm.object(ofType: Entity.self, forPrimaryKey: primaryKey) else {
                                    continuation.resume(throwing: DatabaseError.noRecordToDelete)
                                    throw DatabaseError.noRecordToDelete
                                }
                                realm.delete(result)
                            }
                            continuation.resume(returning: Void())
                        } catch {
                            continuation.resume(throwing: DatabaseError.deleteFailed)
                        }
                    } catch {
                        continuation.resume(throwing: DatabaseError.realmCreationFailed(error))
                    }
                }
            }
        }
    }
    
    func asyncPerformDeleteAll() async throws -> Void {
        return try await withCheckedThrowingContinuation { continuation in
            serialQueue.async {
                autoreleasepool {
                    do {
                        let realm = try self.createRealm()
                        do {
                            try realm.write {
                                let results = realm.objects(Entity.self)
                                realm.delete(results)
                            }
                            
                            continuation.resume(returning: Void())
                        } catch {
                            continuation.resume(throwing: DatabaseError.batchDeleteFailed)
                        }
                    } catch {
                        continuation.resume(throwing: DatabaseError.realmCreationFailed(error))
                    }
                }
            }
        }
    }
    
    // MARK: Batch Operations
    func batchCreate(_ entities: [Entity]) -> AnyPublisher<[Entity], DatabaseError> {
        return Future<[Entity], DatabaseError> { promise in
            self.serialQueue.async {
                autoreleasepool {
                    do {
                        let realm = try self.createRealm()
                        do {
                            try realm.write {
                                realm.add(entities, update: .modified)
                            }
                            promise(.success(entities))
                        } catch {
                            promise(.failure(.insertFailed))
                        }
                    } catch {
                        promise(.failure(.realmCreationFailed(error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func batchDelete(_ primaryKeys: [Entity.PrimaryKeyType]) -> AnyPublisher<Void, DatabaseError> {
        return Future<Void, DatabaseError> { promise in
            self.serialQueue.async {
                autoreleasepool {
                    do {
                        let realm = try self.createRealm()
                        try realm.write {
                            primaryKeys.forEach { primaryKey in
                                if let entity = realm.object(
                                    ofType: Entity.self,
                                    forPrimaryKey: primaryKey
                                ) {
                                    realm.delete(entity)
                                }
                            }
                        }
                        promise(.success(Void()))
                    } catch {
                        promise(.failure(.batchDeleteFailed))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func asyncBatchCreate(_ entities: [Entity]) async throws -> [Entity] {
        return try await withCheckedThrowingContinuation { continuation in
            serialQueue.async {
                autoreleasepool {
                    do {
                        let realm = try self.createRealm()
                        do {
                            try realm.write {
                                realm.add(entities, update: .modified)
                            }
                            continuation.resume(returning: entities)
                        } catch {
                            continuation.resume(throwing: DatabaseError.batchInsertFailed)
                        }
                    } catch {
                        continuation.resume(throwing: DatabaseError.realmCreationFailed(error))
                    }
                }
            }
        }
    }
    
    func asyncBatchDelete(_ primaryKeys: [Entity.PrimaryKeyType]) async throws -> Void {
        return try await withCheckedThrowingContinuation { continuation in
            serialQueue.async {
                autoreleasepool {
                    do {
                        let realm = try self.createRealm()
                        do {
                            var noRecordedPrimaryKeys: [Entity.PrimaryKeyType] = []
                            
                            try realm.write {
                                primaryKeys.forEach { primaryKey in
                                    if let result = realm.object(ofType: Entity.self, forPrimaryKey: primaryKey) {
                                        realm.delete(result)
                                    } else {
                                        noRecordedPrimaryKeys.append(primaryKey)
                                    }
                                }
                            }
                            
                            if noRecordedPrimaryKeys.isEmpty {
                                continuation.resume(returning: Void())
                            } else {
                                continuation.resume(throwing: DatabaseError.batchDeleteFailed)
                            }
                        } catch {
                            continuation.resume(throwing: DatabaseError.deleteFailed)
                        }
                    } catch {
                        continuation.resume(throwing: DatabaseError.realmCreationFailed(error))
                    }
                }
            }
        }
    }
}
