//
//  DatabaseError.swift
//  CoreFoundationKit
//
//  Created by 이숭인 on 5/24/25.
//

import Foundation

public enum DatabaseError: Error {
    // Create
    case insertFailed
    case batchInsertFailed
    
    // Read
    case fetchFailed
    case batchFetchFailed
    
    // Update
    case updateFailed
    case noRecordToUpdate
    case batchUpdateFailed
    
    // Delete
    case deleteFailed
    case noRecordToDelete
    case batchDeleteFailed
    case deleteAllFailed
    
    // Observe
    case observationFailed(Error)
    
    // Realm
    case realmCreationFailed(Error)
}
