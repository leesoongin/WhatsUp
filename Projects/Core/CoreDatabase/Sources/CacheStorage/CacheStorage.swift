//
//  CacheStorage.swift
//  SoongBook
//
//  Created by 이숭인 on 11/27/24.
//

import Foundation
import Combine

@available(macOS 10.15, *)
public final class CacheStorage<Key: CacheKeyable, Object: Cacheable> {
    public typealias ChangedCacheSet = (key: StorageChange<Key>, object: Object?)
    
    private let storageObserverSubject = PassthroughSubject<Result<ChangedCacheSet, StorageError>, Never>()
    
    public let memoryStorage: MemoryStorage<Key, Object>
    public let diskStorage: DiskStorage<Key, Object>
    
    public var storageObserver: AnyPublisher<Result<ChangedCacheSet, StorageError>, Never> {
        storageObserverSubject.eraseToAnyPublisher()
    }
    
    public init(
        memoryConfig: MemoryStorage<Key, Object>.Config,
        diskConfig: DiskStorage<Key, Object>.Config
    ) {
        memoryStorage = MemoryStorage<Key, Object>(config: memoryConfig)
        diskStorage = DiskStorage(config: diskConfig)
        
        print("🏪 CacheStorage 초기화됨 (Memory + Disk)")
    }
    
    deinit {
        print("🗑️ CacheStorage 해제됨")
    }
    
    // MARK: - CRUD Operations
    
    /// 캐시에 값을 저장 (Memory + Disk)
    public func save(
        with value: Object,
        key: Key,
        expiration: CacheStorageExpiration? = nil
    ) {
        let cacheKey = NSCacheKey(value: key)
        
        print("💾 CacheStorage 저장 시작: \(key)")
        
        // 1. 메모리에 즉시 저장
        memoryStorage.saveValue(
            with: value,
            key: cacheKey,
            expiration: expiration
        )
        
        // 2. 디스크에 저장 (Result 방식)
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            
            let diskResult = self.diskStorage.saveValue(
                with: value,
                key: cacheKey,
                expiration: expiration
            )
            
            DispatchQueue.main.async {
                switch diskResult {
                case .success:
                    print("✅ CacheStorage 저장 성공: \(key)")
                    
                    let changeSet: ChangedCacheSet = (
                        key: .save(key: key),
                        object: value
                    )
                    
                    self.storageObserverSubject.send(.success(changeSet))
                    
                case .failure(let error):
                    print("❌ CacheStorage 디스크 저장 실패: \(error)")
                    self.storageObserverSubject.send(.failure(error))
                }
            }
        }
    }
    
    /// 캐시에서 값을 조회 (Memory 우선, Disk 폴백)
    public func retrieve(forKey key: Key) -> Result<Object?, StorageError> {
        let cacheKey = NSCacheKey(value: key)
        
        print("📖 CacheStorage 조회 시작: \(key)")
        
        // 1. 메모리에서 먼저 조회
        if let memoryCachedValue = memoryStorage.retrieveValue(forKey: cacheKey) {
            print("✅ 메모리 캐시 히트: \(key)")
            return .success(memoryCachedValue)
        }
        
        // 2. 디스크에서 조회
        let diskResult = diskStorage.retrieveValue(forKey: cacheKey)
        
        switch diskResult {
        case .success(let diskCachedValue):
            if let value = diskCachedValue {
                print("✅ 디스크 캐시 히트: \(key)")
                
                // 3. 디스크에서 찾은 값을 메모리에 다시 저장 (캐시 프로모션)
                memoryStorage.saveValue(with: value, key: cacheKey)
                
                return .success(value)
            } else {
                print("❌ 캐시 미스: \(key)")
                return .success(nil)
            }
            
        case .failure(let error):
            print("❌ 디스크 캐시 조회 실패: \(error)")
            return .failure(error)
        }
    }
    
    /// 캐시에서 값을 삭제
    public func remove(forKey key: Key) -> Result<Void, StorageError> {
        let cacheKey = NSCacheKey(value: key)
        
        print("🗑️ CacheStorage 삭제 시작: \(key)")
        
        // 삭제 전에 값 조회 (옵저버 알림용)
        let retrievedValue: Object? = {
            switch retrieve(forKey: key) {
            case .success(let value):
                return value
            case .failure:
                return nil
            }
        }()
        
        // 1. 메모리에서 삭제
        memoryStorage.remove(forKey: cacheKey)
        
        // 2. 디스크에서 삭제
        let diskResult = diskStorage.remove(forKey: cacheKey)
        
        switch diskResult {
        case .success:
            print("✅ CacheStorage 삭제 성공: \(key)")
            
            let changeSet: ChangedCacheSet = (
                key: .remove(key: key),
                object: retrievedValue
            )
            
            DispatchQueue.main.async { [weak self] in
                self?.storageObserverSubject.send(.success(changeSet))
            }
            
            return .success(())
            
        case .failure(let error):
            print("❌ CacheStorage 디스크 삭제 실패: \(error)")
            
            DispatchQueue.main.async { [weak self] in
                self?.storageObserverSubject.send(.failure(error))
            }
            
            return .failure(error)
        }
    }
    
    /// 모든 캐시 삭제
    public func removeAll() -> Result<Void, StorageError> {
        print("🧹 CacheStorage 전체 삭제 시작")
        
        // 1. 메모리 캐시 삭제
        memoryStorage.removeAll()
        
        // 2. 디스크 캐시 삭제
        let diskResult = diskStorage.removeAll()
        
        switch diskResult {
        case .success:
            print("✅ CacheStorage 전체 삭제 성공")
            
            let changeSet: ChangedCacheSet = (
                key: .removeAll,
                object: nil
            )
            
            DispatchQueue.main.async { [weak self] in
                self?.storageObserverSubject.send(.success(changeSet))
            }
            
            return .success(())
            
        case .failure(let error):
            print("❌ CacheStorage 전체 삭제 실패: \(error)")
            
            DispatchQueue.main.async { [weak self] in
                self?.storageObserverSubject.send(.failure(error))
            }
            
            return .failure(error)
        }
    }
    
    /// 캐시 여부 확인
    public func isCached(forKey key: Key) -> Bool {
        let cacheKey = NSCacheKey(value: key)
        return memoryStorage.isCached(forKey: cacheKey) || diskStorage.isCached(forKey: cacheKey)
    }
    
    // MARK: - Batch Operations
    
    /// 여러 키에 대한 배치 조회
    public func retrieveBatch(forKeys keys: [Key]) -> [Key: Object?] {
        var results: [Key: Object?] = [:]
        
        for key in keys {
            switch retrieve(forKey: key) {
            case .success(let value):
                results[key] = value
            case .failure:
                results[key] = nil
            }
        }
        
        return results
    }
    
    /// 여러 키-값 쌍의 배치 저장
    public func saveBatch(_ items: [(key: Key, value: Object)], expiration: CacheStorageExpiration? = nil) {
        for item in items {
            save(with: item.value, key: item.key, expiration: expiration)
        }
    }
    
    /// 여러 키의 배치 삭제
    public func removeBatch(forKeys keys: [Key]) -> [Key: Result<Void, StorageError>] {
        var results: [Key: Result<Void, StorageError>] = [:]
        
        for key in keys {
            results[key] = remove(forKey: key)
        }
        
        return results
    }
    
    // MARK: - Cache Management
    
    /// 만료된 캐시 정리
    public func removeExpired() -> Result<Int, StorageError> {
        print("🔍 CacheStorage 만료 캐시 정리 시작")
        
        // 메모리 캐시 정리
        memoryStorage.removeExpired()
        
        // 디스크 캐시 정리
        let diskResult = diskStorage.removeExpired()
        
        switch diskResult {
        case .success(let diskCount):
            print("✅ 만료 캐시 정리 완료 - 디스크: \(diskCount)개")
            return .success(diskCount)
            
        case .failure(let error):
            print("❌ 만료 캐시 정리 실패: \(error)")
            return .failure(error)
        }
    }
}
