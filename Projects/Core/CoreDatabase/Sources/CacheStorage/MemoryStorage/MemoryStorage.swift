//
//  MemoryStorage2.swift
//  CoreUIKit
//
//  Created by 이숭인 on 6/24/25.
//


import Foundation
import Combine

public final class MemoryStorage<Key: CacheKeyable, Object: Cacheable>: NSObject, NSCacheDelegate {
    private let storage = NSCache<NSCacheKey<Key>, NSCacheObject<Object>>()
    private let concurrentQueue = DispatchQueue(label: "com.memoryStorage.concurrent", attributes: .concurrent)
    
    // Thread-safe key tracking using concurrent queue + barrier
    private var _cacheKeys = Set<NSCacheKey<Key>>()
    private var cacheKeys: Set<NSCacheKey<Key>> {
        get {
            return concurrentQueue.sync { _cacheKeys }
        }
        set {
            concurrentQueue.async(flags: .barrier) { [weak self] in
                self?._cacheKeys = newValue
            }
        }
    }
    
    public var config: Config {
        didSet {
            // Config 변경도 thread-safe하게
            concurrentQueue.async(flags: .barrier) { [weak self] in
                self?.storage.totalCostLimit = self?.config.totalCostLimit ?? 0
                self?.storage.countLimit = self?.config.countLimit ?? 0
            }
        }
    }
    
    private var cleanTimer: Timer?
    
    public init(config: Config) {
        self.config = config
        super.init()
        
        // NSCache delegate 설정으로 자동 키 추적
        storage.delegate = self
        storage.totalCostLimit = config.totalCostLimit
        storage.countLimit = config.countLimit
        
        setupTimer()
    }
    
    deinit {
        cleanTimer?.invalidate()
    }
    
    // MARK: - Setup
    
    private func setupTimer() {
        guard config.cleanInterval > 0 else { return }
        
        cleanTimer = Timer.scheduledTimer(withTimeInterval: config.cleanInterval, repeats: true) { [weak self] _ in
            self?.removeExpired()
        }
    }
    
    // MARK: - CRUD Operations
    
    /// Create / Update
    public func saveValue(
        with value: Object,
        key: NSCacheKey<Key>,
        expiration: CacheStorageExpiration? = nil
    ) {
        let expiration = expiration ?? config.expiration
        guard !expiration.isExpired else { return }
        
        let object = NSCacheObject(value, expiration: expiration)
        
        // NSCache는 thread-safe하므로 직접 사용
        storage.setObject(object, forKey: key)
        
        // 키 추가는 barrier로 안전하게
        concurrentQueue.async(flags: .barrier) { [weak self] in
            self?._cacheKeys.insert(key)
        }
    }
    
    /// Read
    public func retrieveValue(forKey key: NSCacheKey<Key>) -> Object? {
        // 읽기 작업은 concurrent 실행 가능
        guard let object = storage.object(forKey: key) else {
            return nil
        }
        
        // 만료 확인 및 지연 삭제
        if object.isExpired {
            removeExpiredObject(forKey: key)
            return nil
        }
        
        return object.value
    }
    
    /// Delete
    public func remove(forKey key: NSCacheKey<Key>) {
        storage.removeObject(forKey: key)
        
        concurrentQueue.async(flags: .barrier) { [weak self] in
            self?._cacheKeys.remove(key)
        }
    }
    
    /// Delete All
    public func removeAll() {
        storage.removeAllObjects()
        
        concurrentQueue.async(flags: .barrier) { [weak self] in
            self?._cacheKeys.removeAll()
        }
    }
    
    /// Check if cached (개선된 버전)
    public func isCached(forKey key: NSCacheKey<Key>) -> Bool {
        guard let object = storage.object(forKey: key) else { return false }
        
        if object.isExpired {
            removeExpiredObject(forKey: key)
            return false
        }
        
        return true
    }
    
    // MARK: - Expiration Management
    
    /// 지연 삭제 방식으로 개선된 만료 객체 제거
    private func removeExpiredObject(forKey key: NSCacheKey<Key>) {
        storage.removeObject(forKey: key)
        
        concurrentQueue.async(flags: .barrier) { [weak self] in
            self?._cacheKeys.remove(key)
        }
    }
    
    /// 배치 만료 제거 (최적화됨)
    public func removeExpired() {
        concurrentQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            var expiredKeys: [NSCacheKey<Key>] = []
            
            // 키 복사본으로 안전한 순회
            let currentKeys = Array(self._cacheKeys)
            
            for key in currentKeys {
                guard let object = self.storage.object(forKey: key) else {
                    // 캐시에 없는 키는 제거
                    self._cacheKeys.remove(key)
                    continue
                }
                
                if object.isExpired {
                    expiredKeys.append(key)
                }
            }
            
            // 만료된 객체들 제거
            for key in expiredKeys {
                self.storage.removeObject(forKey: key)
                self._cacheKeys.remove(key)
            }
            
            if !expiredKeys.isEmpty {
                print("🗑️ \(expiredKeys.count)개의 만료된 캐시 제거됨")
            }
        }
    }
    
    // MARK: - Utility
    
    public func getCurrentCacheCount() -> Int {
        return concurrentQueue.sync { _cacheKeys.count }
    }
    
    // MARK: - NSCacheDelegate
    public func cache(_ cache: NSCache<AnyObject, AnyObject>, willEvictObject obj: Any) {
        print("🚨 NSCache가 객체를 자동 제거합니다!")
        
        if let cacheObject = obj as? NSCacheObject<Object> {
            print("📦 제거되는 객체 타입: \(type(of: cacheObject.value))")
            
            concurrentQueue.async(flags: .barrier) { [weak self] in
                // 실제 키를 찾아서 제거하는 것은 비효율적이므로
                // 주기적으로 동기화하는 방식으로 처리
                self?.scheduleKeySync()
            }
        }
    }
    
    private func scheduleKeySync() {
        print("⏰ 키 동기화가 1초 후에 예약되었습니다")
        
        // 키 동기화를 너무 자주 하지 않도록 디바운스
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.syncKeysWithCache()
        }
    }
    
    private func syncKeysWithCache() {
        print("🔄 NSCache와 cacheKeys 동기화를 시작합니다...")
        
        concurrentQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            let originalCount = self._cacheKeys.count
            var validKeys = Set<NSCacheKey<Key>>()
            
            for key in self._cacheKeys {
                if self.storage.object(forKey: key) != nil {
                    validKeys.insert(key)
                }
            }
            
            let removedCount = originalCount - validKeys.count
            self._cacheKeys = validKeys
            
            if removedCount > 0 {
                print("🧹 동기화 완료: \(removedCount)개의 무효한 키를 제거했습니다")
                print("📊 현재 유효한 키 개수: \(validKeys.count)개")
            } else {
                print("✅ 동기화 완료: 모든 키가 유효합니다 (\(validKeys.count)개)")
            }
        }
    }
    
}
