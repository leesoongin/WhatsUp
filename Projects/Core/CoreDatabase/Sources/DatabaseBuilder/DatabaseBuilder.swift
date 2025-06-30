//
//  DatabaseBuilder.swift
//  CoreFoundationKit
//
//  Created by 이숭인 on 5/24/25.
//

import Foundation
import RealmSwift
import Combine

// MARK: - Core Database Protocols
/// 데이터베이스 엔티티가 준수해야 하는 기본 프로토콜
public protocol DatabaseEntity {
    associatedtype PrimaryKeyType: Hashable
    associatedtype DetachType
    
    var compositeKey: PrimaryKeyType { get }
    func detached() -> DetachType
}

public protocol Persistable: DatabaseEntity {
    init()
}

// MARK: - Migration Protocol
public protocol DatabaseMigration {
    var version: UInt64 { get }
    
    func migrate()
}

// MARK: - Core Database Builder Protocol
public protocol DatabaseBuilder {
    associatedtype Entity: Object & DatabaseEntity
    
    // Configuration
    var realmConfiguration: Realm.Configuration { get }
    var migrations: [DatabaseMigration] { get }
    
    // Thread Management
    var concurrentQueue: DispatchQueue { get }
    var serialQueue: DispatchQueue { get }
    
    // MARK: - Combine API
    func create(_ entity: Entity) -> AnyPublisher<Entity, DatabaseError>
    func read(primaryKey: Entity.PrimaryKeyType) -> AnyPublisher<Entity?, DatabaseError>
    func readAll() -> AnyPublisher<[Entity], DatabaseError>
    func update(_ entity: Entity) -> AnyPublisher<Entity, DatabaseError>
    func delete(primaryKey: Entity.PrimaryKeyType) -> AnyPublisher<Void, DatabaseError>
    func deleteAll() -> AnyPublisher<Void, DatabaseError>
    func query(_ predicate: NSPredicate) -> AnyPublisher<[Entity], DatabaseError>
    func count() -> AnyPublisher<Int, DatabaseError>
    func exists(primaryKey: Entity.PrimaryKeyType) -> AnyPublisher<Bool, DatabaseError>
    func observe() -> AnyPublisher<[Entity], DatabaseError>
    func observe(primaryKey: Entity.PrimaryKeyType) -> AnyPublisher<Entity?, DatabaseError>
    
    // MARK: - Async/Await API
    func asyncCreate(_ entity: Entity) async throws -> Entity
    func asyncRead(primaryKey: Entity.PrimaryKeyType) async throws -> Entity?
    func asyncReadAll() async throws -> [Entity]
    func asyncUpdate(_ entity: Entity) async throws -> Entity
    func asyncDelete(primaryKey: Entity.PrimaryKeyType) async throws -> Void
    func asyncDeleteAll() async throws -> Void
    func asyncQuery(_ predicate: NSPredicate) async throws -> [Entity]
    func asyncCount() async throws -> Int
    func asyncExists(primaryKey: Entity.PrimaryKeyType) async throws -> Bool
    
    // MARK: - Batch Operations
    func batchCreate(_ entities: [Entity]) -> AnyPublisher<[Entity], DatabaseError>
    func batchDelete(_ primaryKeys: [Entity.PrimaryKeyType]) -> AnyPublisher<Void, DatabaseError>
    func asyncBatchCreate(_ entities: [Entity]) async throws -> [Entity]
    func asyncBatchDelete(_ primaryKeys: [Entity.PrimaryKeyType]) async throws -> Void
    
    // MARK: - Internal Operations
    func createRealm() throws -> Realm
    func performRead(with primaryKey: Entity.PrimaryKeyType) -> AnyPublisher<Entity?, DatabaseError>
    func performQuery(with predicate: NSPredicate) -> AnyPublisher<[Entity], DatabaseError>
    func performReadAll() -> AnyPublisher<[Entity], DatabaseError>
    func performWrite(entity: Entity) -> AnyPublisher<Entity, DatabaseError>
    func performDelete(_ primaryKey: Entity.PrimaryKeyType) -> AnyPublisher<Void, DatabaseError>
    func performDeleteAll() -> AnyPublisher<Void, DatabaseError>
    
    func asyncPerformRead(primaryKey: Entity.PrimaryKeyType) async throws -> Entity?
    func asyncPerformReadAll() async throws -> [Entity]
    func asyncPerformWrite(_ entity: Entity) async throws -> Entity
    func asyncPerformDelete(primaryKey: Entity.PrimaryKeyType) async throws -> Void
    func asyncPerformDeleteAll() async throws -> Void
}
