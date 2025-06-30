//
//  LocalRepository.swift
//  LinkSavingFeature
//
//  Created by 이숭인 on 5/21/25.
//

import Foundation
import Combine
import CoreDatabase
import CoreFoundationKit
import LinkSavingInterface

struct DatabaseErrorMapper: ErrorMapper {
    func map(_ error: DatabaseError) -> LinkItemError {
        switch error {
        case .insertFailed:
            return .addFailed
        case .batchInsertFailed:
            return .batchAddFailed
        case .fetchFailed:
            return .fetchFailed
        case .batchFetchFailed:
            return .batchFetchFailed
        case .updateFailed:
            return .updateFailed
        case .noRecordToUpdate:
            return .noRecordToUpdate
        case .batchUpdateFailed:
            return .batchUpdateFailed
        case .deleteFailed:
            return .deleteFailed
        case .noRecordToDelete:
            return .noRecordToDelete
        case .batchDeleteFailed:
            return .batchDeleteFailed
        case .deleteAllFailed:
            return .deleteAllFailed
        case .observationFailed(let error):
            return .observationFailed(error)
        case .realmCreationFailed(let error):
            return .realmCreationFailed(error)
        }
    }
}

struct LinkItemDatabaseBuilder: DatabaseBuilder {
    typealias Entity = LinkItemDTO
}

final class LinkItemLocalRepositoryImpl: LinkItemLocalRepository {
    private let errorMapper: DatabaseErrorMapper
    
    private var cancellables = Set<AnyCancellable>()
    private let linkItemDatabaseBuilder: LinkItemDatabaseBuilder
    
    init(
        linkItemDatabaseBuilder: LinkItemDatabaseBuilder,
        errorMapper: DatabaseErrorMapper
    ) {
        self.linkItemDatabaseBuilder = linkItemDatabaseBuilder
        self.errorMapper = errorMapper
    }
    
    func add(with item: LinkItem) -> AnyPublisher<LinkItem, LinkItemError> {
        let dtoModel = LinkItemMappaer.toDTO(domain: item)
        
        return linkItemDatabaseBuilder.create(dtoModel)
            .tryMap { LinkItemMappaer.from(dto: $0) }
            .mapError { [weak self] databaseError in
                guard let dbError = databaseError as? DatabaseError,
                      let errorMapper = self?.errorMapper else {
                    return LinkItemError.unknown
                }
                
                return errorMapper.map(dbError)
            }
            .eraseToAnyPublisher()
    }
    
    func loadAll() -> AnyPublisher<[LinkItem], LinkItemError> {
        return linkItemDatabaseBuilder.readAll()
            .tryMap { linkItems in
                linkItems.map { LinkItemMappaer.from(dto: $0) }
            }
            .mapError { [weak self] databaseError in
                guard let dbError = databaseError as? DatabaseError,
                      let errorMapper = self?.errorMapper else {
                    return LinkItemError.unknown
                }
                
                return errorMapper.map(dbError)
            }
            .eraseToAnyPublisher()
    }
    
    func read(with primaryKey: String) -> AnyPublisher<LinkItem, LinkItemError> {
        linkItemDatabaseBuilder.read(primaryKey: primaryKey)
            .tryMap { linkItemDTO in
                guard let linkItemDTO = linkItemDTO else {
                    throw LinkItemError.notFound
                }
                return LinkItemMappaer.from(dto: linkItemDTO)
            }
            .mapError { [weak self] databaseError in
                guard let dbError = databaseError as? DatabaseError,
                      let errorMapper = self?.errorMapper else {
                    return LinkItemError.unknown
                }
                
                return errorMapper.map(dbError)
            }
            .eraseToAnyPublisher()
    }
    
    func remove(with primaryKey: String) -> AnyPublisher<Void, LinkItemError> {
        linkItemDatabaseBuilder.delete(primaryKey: primaryKey)
            .tryMap { _ in return Void() }
            .mapError { [weak self] databaseError in
                guard let dbError = databaseError as? DatabaseError,
                      let errorMapper = self?.errorMapper else {
                    return LinkItemError.unknown
                }
                
                return errorMapper.map(dbError)
            }
            .eraseToAnyPublisher()
    }
    
    func removeAll() -> AnyPublisher<Void, LinkItemError> {
        linkItemDatabaseBuilder.deleteAll()
            .tryMap { _ in return Void() }
            .mapError { [weak self] databaseError in
                guard let dbError = databaseError as? DatabaseError,
                      let errorMapper = self?.errorMapper else {
                    return LinkItemError.unknown
                }
                
                return errorMapper.map(dbError)
            }
            .eraseToAnyPublisher()
    }
}
