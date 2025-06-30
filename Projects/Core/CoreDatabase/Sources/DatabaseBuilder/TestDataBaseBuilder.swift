//
//  TestDataBaseBuilder.swift
//  CoreDatabase
//
//  Created by 이숭인 on 6/14/25.
//

import Foundation
import RealmSwift

// MARK: - Core Database Protocols
/// 데이터베이스 엔티티가 준수해야 하는 기본 프로토콜
//public protocol DatabaseEntity {
//    associatedtype PrimaryKeyType: Hashable
//    associatedtype DetachType
//    
//    var compositeKey: PrimaryKeyType { get }
//    func detached() -> DetachType
//}

//public protocol Persistable: DatabaseEntity {
//    init()
//}

// MARK: - Migration Protocol
//public protocol DatabaseMigration {
//    var version: UInt64 { get }
//    
//    func migrate()
//}

// MARK: - Core Database Builder Protocol
@available(iOS 13.0, *)
public protocol AsyncDatabaseBuilder: Actor {
    associatedtype Entity: Object & DatabaseEntity
    
    // Configuration
    var realmConfiguration: Realm.Configuration { get }
    var migrations: [DatabaseMigration] { get }
    
    // MARK: - Async/Await API
    func create(_ entity: Entity) async throws -> Entity
    func read(primaryKey: Entity.PrimaryKeyType) async throws -> Entity
    func readAll() async throws -> [Entity]
    func update(_ entity: Entity) async throws -> Entity
    func delete(primaryKey: Entity.PrimaryKeyType) async throws -> Void
    func deleteAll() async throws -> Void
    func query(_ predicate: NSPredicate) async throws -> [Entity]
    func count() async throws -> Int
    func exists(primaryKey: Entity.PrimaryKeyType) async throws -> Bool
    
    // MARK: - Observation (AsyncSequence 기반)
    func observeAll() -> AsyncThrowingStream<[Entity], Error>
    func observe(primaryKey: Entity.PrimaryKeyType) -> AsyncThrowingStream<Entity?, Error>
    
    // MARK: - Batch Operations
    func batchCreate(_ entities: [Entity]) async throws -> [Entity]
    func batchDelete(_ primaryKeys: [Entity.PrimaryKeyType]) async throws -> Void
    func batchUpdate(_ entities: [Entity]) async throws -> [Entity]
    
    // MARK: - Internal Operations (Actor 내부 처리)
    func createRealm() throws -> Realm
    func performRead(primaryKey: Entity.PrimaryKeyType) async throws -> Entity
    func performQuery(predicate: NSPredicate) async throws -> [Entity]
    func performReadAll() async throws -> [Entity]
    func performWrite(_ entity: Entity) async throws -> Entity
    func performDelete(primaryKey: Entity.PrimaryKeyType) async throws -> Void
    func performDeleteAll() async throws -> Void
}

// MARK: - Database Error
public enum AsyncDatabaseError: Error, LocalizedError {
    case realmCreationFailed(Error)
    case notFound
    case insertFailed
    case updateFailed
    case deleteFailed
    case deleteAllFailed
    case batchInsertFailed
    case batchDeleteFailed
    case noRecordToDelete
    case observationFailed(Error)
    case queryFailed(Error)
    case invalidPrimaryKey
    
    public var errorDescription: String? {
        switch self {
        case .realmCreationFailed(let error):
            return "Realm creation failed: \(error.localizedDescription)"
        case .notFound:
            return "Not Found"
        case .insertFailed:
            return "Insert operation failed"
        case .updateFailed:
            return "Update operation failed"
        case .deleteFailed:
            return "Delete operation failed"
        case .deleteAllFailed:
            return "Delete all operation failed"
        case .batchInsertFailed:
            return "Batch insert operation failed"
        case .batchDeleteFailed:
            return "Batch delete operation failed"
        case .noRecordToDelete:
            return "No record found to delete"
        case .observationFailed(let error):
            return "Observation failed: \(error.localizedDescription)"
        case .queryFailed(let error):
            return "Query failed: \(error.localizedDescription)"
        case .invalidPrimaryKey:
            return "Invalid primary key provided"
        }
    }
}

//
//  DatabaseBuilder+Extension.swift
//  CoreFoundationKit
//
//  Created by 이숭인 on 5/24/25.
//

// MARK: - Default Configuration
@available(iOS 13.0, *)
public extension AsyncDatabaseBuilder {
    var realmConfiguration: Realm.Configuration {
        let config = Realm.Configuration(
            schemaVersion: 1,
            deleteRealmIfMigrationNeeded: true
        )
        Realm.Configuration.defaultConfiguration = config
        return Realm.Configuration.defaultConfiguration
    }
    
    var migrations: [DatabaseMigration] {
        return []
    }
}

// MARK: - CRUD Operations Implementation
@available(iOS 13.0, *)
public extension AsyncDatabaseBuilder {
    //TODO: Concurrency 는 return 할 필요가 있을까? 어차피 호출부에는 있읉텐데
    func create(_ entity: Entity) async throws -> Entity {
        return try await performWrite(entity)
    }
    
    func read(primaryKey: Entity.PrimaryKeyType) async throws -> Entity {
        return try await performRead(primaryKey: primaryKey)
    }
    
    func readAll() async throws -> [Entity] {
        return try await performReadAll()
    }
    
    func update(_ entity: Entity) async throws -> Entity {
        return try await performWrite(entity) // Realm의 upsert 특성 활용
    }
    
    func delete(primaryKey: Entity.PrimaryKeyType) async throws -> Void {
        try await performDelete(primaryKey: primaryKey)
    }
    
    func deleteAll() async throws -> Void {
        try await performDeleteAll()
    }
    
    func query(_ predicate: NSPredicate) async throws -> [Entity] {
        return try await performQuery(predicate: predicate)
    }
    
    func count() async throws -> Int {
        let entities = try await performReadAll()
        return entities.count
    }
    
    func exists(primaryKey: Entity.PrimaryKeyType) async throws -> Bool {
        do {
            _ = try await performRead(primaryKey: primaryKey)
            return true
        } catch {
            throw AsyncDatabaseError.notFound
        }
    }
}

// MARK: - Internal Operations Implementation
@available(iOS 13.0, *)
public extension AsyncDatabaseBuilder {
    func createRealm() throws -> Realm {
        return try Realm(configuration: realmConfiguration)
    }
    
    func performRead(primaryKey: Entity.PrimaryKeyType) async throws -> Entity {
        do {
            let realm = try createRealm()
            realm.refresh()

            guard let entity = realm.object(ofType: Entity.self, forPrimaryKey: primaryKey) else {
                throw AsyncDatabaseError.notFound
            }
            return entity
        } catch {
            throw AsyncDatabaseError.realmCreationFailed(error)
        }
    }
    
    func performQuery(predicate: NSPredicate) async throws -> [Entity] {
        do {
            let realm = try createRealm()
            realm.refresh()
            return Array(realm.objects(Entity.self).filter(predicate))
        } catch {
            throw AsyncDatabaseError.queryFailed(error)
        }
    }
    
    func performReadAll() async throws -> [Entity] {
        do {
            let realm = try createRealm()
            realm.refresh()
            return Array(realm.objects(Entity.self))
        } catch {
            throw AsyncDatabaseError.realmCreationFailed(error)
        }
    }
    
    func performWrite(_ entity: Entity) async throws -> Entity {
        do {
            let realm = try createRealm()
            try realm.write {
                realm.add(entity, update: .modified)
            }
            return entity
        } catch {
            if error is DatabaseError {
                throw error
            } else {
                throw DatabaseError.insertFailed
            }
        }
    }
    
    func performDelete(primaryKey: Entity.PrimaryKeyType) async throws -> Void {
        do {
            let realm = try createRealm()
            try realm.write {
                guard let entity = realm.object(ofType: Entity.self, forPrimaryKey: primaryKey) else {
                    throw DatabaseError.noRecordToDelete
                }
                realm.delete(entity)
            }
        } catch {
            if error is DatabaseError {
                throw error
            } else {
                throw DatabaseError.deleteFailed
            }
        }
    }
    
    func performDeleteAll() async throws -> Void {
        do {
            let realm = try createRealm()
            try realm.write {
                let entities = realm.objects(Entity.self)
                realm.delete(entities)
            }
        } catch {
            throw DatabaseError.deleteAllFailed
        }
    }
}

// MARK: - Batch Operations Implementation
@available(iOS 13.0, *)
public extension AsyncDatabaseBuilder {
    func batchCreate(_ entities: [Entity]) async throws -> [Entity] {
        do {
            let realm = try createRealm()
            try realm.write {
                realm.add(entities, update: .modified)
            }
            return entities
        } catch {
            throw DatabaseError.batchInsertFailed
        }
    }
    
    func batchDelete(_ primaryKeys: [Entity.PrimaryKeyType]) async throws -> Void {
        do {
            let realm = try createRealm()
            try realm.write {
                for primaryKey in primaryKeys {
                    if let entity = realm.object(ofType: Entity.self, forPrimaryKey: primaryKey) {
                        realm.delete(entity)
                    }
                }
            }
        } catch {
            throw DatabaseError.batchDeleteFailed
        }
    }
    
    func batchUpdate(_ entities: [Entity]) async throws -> [Entity] {
        return try await batchCreate(entities) // Realm의 upsert 특성 활용
    }
}

// MARK: - Observation Implementation (AsyncSequence 기반)
@available(iOS 13.0, *)
public extension AsyncDatabaseBuilder {
    func observeAll() -> AsyncThrowingStream<[Entity], Error> {
        return AsyncThrowingStream { continuation in
            Task { @MainActor in
                do {
                    let realm = try await createRealm()
                    let results = realm.objects(Entity.self)
                    
                    let token = results.observe { changes in
                        switch changes {
                        case .initial(let collection):
                            let entities = Array(collection)
                            continuation.yield(entities)
                            
                        case .update(let collection, _, _, _):
                            let entities = Array(collection)
                            continuation.yield(entities)
                            
                        case .error(let error):
                            continuation.finish(throwing: DatabaseError.observationFailed(error))
                        }
                    }
                    
                    continuation.onTermination = { _ in
                        token.invalidate()
                    }
                    
                } catch {
                    continuation.finish(throwing: DatabaseError.realmCreationFailed(error))
                }
            }
        }
    }
    
    func observe(primaryKey: Entity.PrimaryKeyType) -> AsyncThrowingStream<Entity?, Error> {
        return AsyncThrowingStream { continuation in
            Task { @MainActor in
                do {
                    let realm = try await createRealm()
                    
                    if let entity = realm.object(ofType: Entity.self, forPrimaryKey: primaryKey) {
                        let token = entity.observe { change in
                            switch change {
                            case .change(let object, _):
                                if let castedObject = object as? Entity {
                                    continuation.yield(castedObject)
                                }
                                
                            case .deleted:
                                continuation.yield(nil)
                                
                            case .error(let error):
                                continuation.finish(throwing: DatabaseError.observationFailed(error))
                            }
                        }
                        
                        continuation.onTermination = { _ in
                            token.invalidate()
                        }
                    } else {
                        continuation.yield(nil)
                        continuation.finish()
                    }
                    
                } catch {
                    continuation.finish(throwing: DatabaseError.realmCreationFailed(error))
                }
            }
        }
    }
}

//
//  DatabaseActorRepository.swift
//  CoreFoundationKit
//
//  Created by 이숭인 on 5/24/25.
//

// MARK: - Concrete Actor Implementation
@available(iOS 13.0, *)
public actor DatabaseActorRepository<Entity: Object & DatabaseEntity>: AsyncDatabaseBuilder {
    public typealias Entity = Entity
    
    // MARK: - Private Properties
    private var cachedRealm: Realm?
    private let _realmConfiguration: Realm.Configuration
    private let _migrations: [DatabaseMigration]
    
    // MARK: - Protocol Properties
    public var realmConfiguration: Realm.Configuration {
        return _realmConfiguration
    }
    
    public var migrations: [DatabaseMigration] {
        return _migrations
    }
    
    // MARK: - Initializer
    public init(
        configuration: Realm.Configuration? = nil,
        migrations: [DatabaseMigration] = []
    ) {
        self._realmConfiguration = configuration ?? {
            let config = Realm.Configuration(
                schemaVersion: 1,
                deleteRealmIfMigrationNeeded: true
            )
            return config
        }()
        self._migrations = migrations
    }
    
    // MARK: - Enhanced Realm Creation (캐싱 적용)
    public func createRealm() throws -> Realm {
        if let cached = cachedRealm, !cached.isFrozen {
            return cached
        }
        
        let newRealm = try Realm(configuration: realmConfiguration)
        cachedRealm = newRealm
        return newRealm
    }
    
    // MARK: - Additional Convenience Methods
    public func refresh() async throws {
        let realm = try createRealm()
        realm.refresh()
    }
    
    public func invalidateCache() async {
        cachedRealm?.invalidate()
        cachedRealm = nil
    }
    
    // 특정 조건으로 검색
    public func findFirst(where predicate: NSPredicate) async throws -> Entity? {
        let results = try await performQuery(predicate: predicate)
        return results.first
    }
    
    // 정렬된 결과 반환
    public func readAllSorted(by keyPath: String, ascending: Bool = true) async throws -> [Entity] {
        do {
            let realm = try createRealm()
            realm.refresh()
            return Array(realm.objects(Entity.self).sorted(byKeyPath: keyPath, ascending: ascending))
        } catch {
            throw DatabaseError.realmCreationFailed(error)
        }
    }
    
    // 페이징 지원
    public func readPage(offset: Int, limit: Int) async throws -> [Entity] {
        do {
            let realm = try createRealm()
            realm.refresh()
            let results = realm.objects(Entity.self)
            let endIndex = min(offset + limit, results.count)
            
            guard offset < results.count else {
                return []
            }
            
            return Array(results[offset..<endIndex])
        } catch {
            throw DatabaseError.realmCreationFailed(error)
        }
    }
}

//
//  Usage Example
//  사용법 예시
//

// MARK: - Entity 정의 예시
class UserEntity: Object, DatabaseEntity {
    @Persisted var id: String = UUID().uuidString
    @Persisted var name: String = ""
    @Persisted var email: String = ""
    @Persisted var createdAt: Date = Date()
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    // DatabaseEntity 프로토콜 구현
    typealias PrimaryKeyType = String
    typealias DetachType = UserEntity
    
    var compositeKey: String {
        return id
    }
    
    func detached() -> UserEntity {
        let detached = UserEntity()
        detached.id = self.id
        detached.name = self.name
        detached.email = self.email
        detached.createdAt = self.createdAt
        return detached
    }
}

// MARK: - 사용법 예시
@available(iOS 13.0, *)
class UsageExample {
    private let userRepository = DatabaseActorRepository<UserEntity>()
    
    func exampleUsage() async {
        do {
            // 사용자 생성
            let user = UserEntity()
            user.name = "John Doe"
            user.email = "john@example.com"
            
            let createdUser = try await userRepository.create(user)
            print("Created user: \(createdUser.name)")
            
            // 모든 사용자 조회
            let allUsers = try await userRepository.readAll()
            print("Total users: \(allUsers.count)")
            
            // 특정 사용자 조회
            let foundUser = try await userRepository.read(primaryKey: user.id)
            print("Found user: \(foundUser.name)")
            
            // 쿼리로 검색
            let predicate = NSPredicate(format: "name CONTAINS[c] %@", "John")
            let searchResults = try await userRepository.query(predicate)
            print("Search results: \(searchResults.count)")
            
            // 배치 작업
            let newUsers = [UserEntity(), UserEntity(), UserEntity()]
            let batchCreated = try await userRepository.batchCreate(newUsers)
            print("Batch created: \(batchCreated.count)")
            
            // 관찰 (AsyncSequence)
            for try await users in await userRepository.observeAll() {
                print("Users updated: \(users.count)")
                break // 예시이므로 첫 번째 이벤트만 처리
            }
            
        } catch {
            print("Error: \(error)")
        }
    }
}
