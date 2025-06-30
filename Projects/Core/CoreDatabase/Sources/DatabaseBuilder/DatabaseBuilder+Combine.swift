//
//  DatabaseBuilder+Combine.swift
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
        return performWrite(entity: entity)
    }
    
    func read(primaryKey: Entity.PrimaryKeyType) -> AnyPublisher<Entity?, DatabaseError> {
        performRead(with: primaryKey)
    }
    
    func readAll() -> AnyPublisher<[Entity], DatabaseError> {
        return performReadAll()
    }
    
    func update(_ entity: Entity) -> AnyPublisher<Entity, DatabaseError> {
        return create(entity) // Realm의 upsert 특성 활용
    }
    
    func delete(primaryKey: Entity.PrimaryKeyType) -> AnyPublisher<Void, DatabaseError> {
        return performDelete(primaryKey)
    }
    
    func deleteAll() -> AnyPublisher<Void, DatabaseError> {
        return performDeleteAll()
    }
    
    func query(_ predicate: NSPredicate) -> AnyPublisher<[Entity], DatabaseError> {
        return performQuery(with: predicate)
    }
    
    func count() -> AnyPublisher<Int, DatabaseError> {
        return performReadAll()
            .map { $0.count }
            .eraseToAnyPublisher()
    }
    
    func exists(primaryKey: Entity.PrimaryKeyType) -> AnyPublisher<Bool, DatabaseError> {
        return performRead(with: primaryKey)
            .map { $0 != nil }
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
                    
                    notificationToken = results.observe { changes in
                        switch changes {
                        case .initial(let collection):
                            let detachedEntities = Array(collection)
                            subject.send(detachedEntities)
                            
                        case .update(let collection, _, _, _):
                            let detachedEntities = Array(collection)
                            subject.send(detachedEntities)
                            
                        case .error(let error):
                            subject.send(completion: .failure(.observationFailed(error)))
                        }
                    }
                } catch {
                    subject.send(completion: .failure(.realmCreationFailed(error)))
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
                        notificationToken = entity.observe { change in
                            switch change {
                            case .change(let object, _):
                                if let castedObject = object as? Entity {
                                    subject.send(castedObject)
                                }
                                
                            case .deleted:
                                subject.send(nil)
                                
                            case .error(let error):
                                subject.send(completion: .failure(.observationFailed(error)))
                            }
                        }
                    } else {
                        subject.send(nil)
                    }
                    
                } catch {
                    subject.send(completion: .failure(.realmCreationFailed(error)))
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
