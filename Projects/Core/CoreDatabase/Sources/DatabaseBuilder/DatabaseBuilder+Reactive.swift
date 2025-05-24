//
//  DatabaseBuilder+CombineInterface.swift
//  CoreFoundationKit
//
//  Created by 이숭인 on 5/24/25.
//

import Foundation
import RealmSwift
import Combine

// MARK: - Reactive CRUD Operations
public extension DatabaseBuilder {
    func create(_ entity: Entity) -> AnyPublisher<Entity, DatabaseError> {
        let entityToSave = entity.realm != nil ? createDetachedCopy(of: entity) : entity
        
        return performWrite { realm in
            realm.add(entityToSave, update: .modified)
            return entityToSave
        }
        .map { [self] savedEntity in
            createDetachedCopy(of: savedEntity)
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    func read(primaryKey: Entity.PrimaryKeyType) -> AnyPublisher<Entity?, DatabaseError> {
        return performRead { realm in
            return realm.object(ofType: Entity.self, forPrimaryKey: primaryKey)
        }
        .map { [self] entity in
            entity.map { createDetachedCopy(of: $0) }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    func readAll() -> AnyPublisher<[Entity], DatabaseError> {
        return performRead { realm in
            return Array(realm.objects(Entity.self))
        }
        .map { [self] entities in
            createDetachedCopies(of: entities)
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    func update(_ entity: Entity) -> AnyPublisher<Entity, DatabaseError> {
        return create(entity) // Realm의 upsert 특성 활용
    }
    
    func delete(primaryKey: Entity.PrimaryKeyType) -> AnyPublisher<Void, DatabaseError> {
        return performWrite { realm in
            guard let entity = realm.object(ofType: Entity.self, forPrimaryKey: primaryKey) else {
                throw DatabaseError.entityNotFound
            }
            realm.delete(entity)
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    func deleteAll() -> AnyPublisher<Void, DatabaseError> {
        return performWrite { realm in
            let entities = realm.objects(Entity.self)
            realm.delete(entities)
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    func query(_ predicate: NSPredicate) -> AnyPublisher<[Entity], DatabaseError> {
        return performRead { realm in
            return Array(realm.objects(Entity.self).filter(predicate))
        }
        .map { [self] entities in
            createDetachedCopies(of: entities)
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    func count() -> AnyPublisher<Int, DatabaseError> {
        return performRead { realm in
            return realm.objects(Entity.self).count
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    func exists(primaryKey: Entity.PrimaryKeyType) -> AnyPublisher<Bool, DatabaseError> {
        return performRead { realm in
            return realm.object(ofType: Entity.self, forPrimaryKey: primaryKey) != nil
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    func observe() -> AnyPublisher<[Entity], DatabaseError> {
        let subject = PassthroughSubject<[Entity], DatabaseError>()
        var notificationToken: NotificationToken?
        
        DispatchQueue.main.async {
            autoreleasepool {
                do {
                    let realm = try self.createRealm()
                    let results = realm.objects(Entity.self)
                    
                    notificationToken = results.observe { [self] changes in
                        switch changes {
                        case .initial(let collection):
                            let detachedEntities = self.createDetachedCopies(of: Array(collection))
                            subject.send(detachedEntities)
                            
                        case .update(let collection, _, _, _):
                            let detachedEntities = self.createDetachedCopies(of: Array(collection))
                            subject.send(detachedEntities)
                            
                        case .error(let error):
                            subject.send(completion: .failure(.queryFailed(error)))
                        }
                    }
                } catch {
                    subject.send(completion: .failure(.realmNotAvailable))
                }
            }
        }
        
        return subject
            .handleEvents(receiveCancel: {
                notificationToken?.invalidate()
                notificationToken = nil
            })
            .eraseToAnyPublisher()
    }
    
    func observe(primaryKey: Entity.PrimaryKeyType) -> AnyPublisher<Entity?, DatabaseError> {
        let subject = PassthroughSubject<Entity?, DatabaseError>()
        var notificationToken: NotificationToken?
        
        DispatchQueue.main.async {
            autoreleasepool {
                do {
                    let realm = try self.createRealm()
                    
                    if let entity = realm.object(ofType: Entity.self, forPrimaryKey: primaryKey) {
                        notificationToken = entity.observe { [self] change in
                            switch change {
                            case .change(let object, _):
                                if let castedObject = object as? Entity {
                                    let detachedEntity = self.createDetachedCopy(of: castedObject)
                                    subject.send(detachedEntity)
                                }
                                
                            case .deleted:
                                subject.send(nil)
                                
                            case .error(let error):
                                subject.send(completion: .failure(.queryFailed(error)))
                            }
                        }
                    } else {
                        subject.send(nil)
                    }
                    
                } catch {
                    subject.send(completion: .failure(.realmNotAvailable))
                }
            }
        }
        
        return subject
            .handleEvents(receiveCancel: {
                notificationToken?.invalidate()
                notificationToken = nil
            })
            .eraseToAnyPublisher()
    }
}
