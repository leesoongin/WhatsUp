//
//  DiskStorage.swift
//  SoongBook
//
//  Created by 이숭인 on 11/27/24.
//
import Foundation

public final class DiskStorage<Key: CacheKeyable, Object: Cacheable> {
    private let concurrentQueue = DispatchQueue(label: "com.diskStorage.concurrent", attributes: .concurrent)
    
    private let fileManager: FileManager
    private let cacheDirectoryURL: URL
    
    public var config: Config {
        didSet {
            print("⚙️ DiskStorage 설정이 변경되었습니다")
        }
    }
    
    private var cleanTimer: Timer?
    
    public init(config: Config) {
        self.config = config
        self.fileManager = FileManager.default
        
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.diskStorage"
        self.cacheDirectoryURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent(bundleIdentifier)
            .appendingPathComponent("DiskCache")
        
        createCacheDirectoryIfNeeded()
        setupTimer()
        
        print("📁 DiskStorage 초기화됨: \(cacheDirectoryURL.path)")
    }
    
    deinit {
        cleanTimer?.invalidate()
        print("🗑️ DiskStorage 해제됨")
    }
    
    // MARK: - Setup
    
    private func setupTimer() {
        guard config.cleanInterval > 0 else { return }
        
        cleanTimer = Timer.scheduledTimer(withTimeInterval: config.cleanInterval, repeats: true) { [weak self] _ in
            print("⏰ 디스크 캐시 정리 타이머 실행")
            _ = self?.removeExpired()
        }
    }
    
    // MARK: - Sync CRUD Operations (Result 반환)
    
    /// 디스크에 값을 저장
    public func saveValue(
        with value: Object,
        key: NSCacheKey<Key>,
        expiration: CacheStorageExpiration? = nil
    ) -> Result<Void, StorageError> {
        let expiration = expiration ?? config.expiration
        guard !expiration.isExpired else {
            print("⚠️ 만료된 expiration으로 저장 요청 - 스킵됨")
            return .failure(.expired)
        }
        
        return concurrentQueue.sync(flags: .barrier) { [weak self] in
            guard let self = self else {
                return .failure(.unknown)
            }
            
            print("💾 디스크 저장 시작: \(key.value.diskKeyPath)")
            
            let object = NSCacheObject(value, expiration: expiration)
            let filePath = self.cacheFilePath(forKey: key)
            
            do {
                let data = try self.encodeObject(with: object)
                try self.writeData(with: data, to: filePath)
                
                print("✅ 디스크 저장 성공: \(filePath.lastPathComponent)")
                return .success(())
            } catch {
                print("❌ 디스크 저장 실패: \(error)")
                if let storageError = error as? StorageError {
                    return .failure(storageError)
                } else {
                    return .failure(.diskWriteFailure)
                }
            }
        }
    }
    
    /// 디스크에서 값을 읽어오기
    public func retrieveValue(forKey key: NSCacheKey<Key>) -> Result<Object?, StorageError> {
        return concurrentQueue.sync { [weak self] in
            guard let self = self else {
                return .failure(.unknown)
            }
            
            print("📖 디스크 읽기 시작: \(key.value.diskKeyPath)")
            
            do {
                let filePath = self.cacheFilePath(forKey: key)
                let data = try self.loadData(from: filePath)
                let object = try self.decodeObject(with: data)
                
                if object.isExpired {
                    print("⏰ 만료된 캐시 발견 - 삭제 후 nil 반환")
                    try? self.fileManager.removeItem(at: filePath)
                    return .success(nil)
                } else {
                    print("✅ 디스크 읽기 성공: \(filePath.lastPathComponent)")
                    return .success(object.value)
                }
            } catch {
                print("❌ 디스크 읽기 실패: \(error)")
                if let storageError = error as? StorageError {
                    return .failure(storageError)
                } else {
                    return .failure(.notFound)
                }
            }
        }
    }
    
    /// 디스크에서 값을 삭제
    public func remove(forKey key: NSCacheKey<Key>) -> Result<Void, StorageError> {
        return concurrentQueue.sync(flags: .barrier) { [weak self] in
            guard let self = self else {
                return .failure(.unknown)
            }
            
            print("🗑️ 디스크 삭제 시작: \(key.value.diskKeyPath)")
            
            let filePath = self.cacheFilePath(forKey: key)
            
            do {
                try self.fileManager.removeItem(at: filePath)
                print("✅ 디스크 삭제 성공: \(filePath.lastPathComponent)")
                return .success(())
            } catch {
                print("❌ 디스크 삭제 실패: \(error)")
                return .failure(.diskRemoveFailure)
            }
        }
    }
    
    /// 디스크에서 모든 캐시 항목 삭제
    public func removeAll() -> Result<Void, StorageError> {
        return concurrentQueue.sync(flags: .barrier) { [weak self] in
            guard let self = self else {
                return .failure(.unknown)
            }
            
            print("🧹 전체 디스크 캐시 삭제 시작")
            
            do {
                let contents = try self.fileManager.contentsOfDirectory(at: self.cacheDirectoryURL, includingPropertiesForKeys: nil)
                
                for fileURL in contents {
                    try self.fileManager.removeItem(at: fileURL)
                }
                
                print("✅ 전체 디스크 캐시 삭제 완료: \(contents.count)개 파일")
                return .success(())
            } catch {
                print("❌ 전체 삭제 실패: \(error)")
                return .failure(.diskRemoveFailure)
            }
        }
    }
    
    /// 만료된 캐시 항목 자동 삭제
    public func removeExpired() -> Result<Int, StorageError> {
        return concurrentQueue.sync(flags: .barrier) { [weak self] in
            guard let self = self else {
                return .failure(.unknown)
            }
            
            print("🔍 만료된 디스크 캐시 검사 시작")
            
            do {
                let contents = try self.fileManager.contentsOfDirectory(
                    at: self.cacheDirectoryURL,
                    includingPropertiesForKeys: [.contentModificationDateKey]
                )
                
                var expiredCount = 0
                let currentDate = Date()
                
                for fileURL in contents {
                    if let resourceValues = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]),
                       let modificationDate = resourceValues.contentModificationDate {
                        
                        let ageLimit: TimeInterval = 24 * 60 * 60 * 7 // 7일
                        if currentDate.timeIntervalSince(modificationDate) > ageLimit {
                            try? self.fileManager.removeItem(at: fileURL)
                            expiredCount += 1
                            continue
                        }
                    }
                    
                    if let data = try? Data(contentsOf: fileURL),
                       let object = try? JSONDecoder().decode(NSCacheObject<Object>.self, from: data),
                       object.isExpired {
                        try? self.fileManager.removeItem(at: fileURL)
                        expiredCount += 1
                    }
                }
                
                if expiredCount > 0 {
                    print("🗑️ 만료된 디스크 캐시 제거 완료: \(expiredCount)개 파일")
                } else {
                    print("✅ 만료된 디스크 캐시 없음")
                }
                
                return .success(expiredCount)
            } catch {
                print("❌ 만료 캐시 정리 실패: \(error)")
                return .failure(.diskRemoveFailure)
            }
        }
    }
    
    /// 캐시 여부 확인
    public func isCached(forKey key: NSCacheKey<Key>) -> Bool {
        switch retrieveValue(forKey: key) {
        case .success(let value):
            return value != nil
        case .failure:
            return false
        }
    }
    
    /// 현재 캐시 크기 조회
    public func getCurrentCacheSize() -> Result<Int64, StorageError> {
        return concurrentQueue.sync { [weak self] in
            guard let self = self else {
                return .failure(.unknown)
            }
            
            var totalSize: Int64 = 0
            
            do {
                let contents = try self.fileManager.contentsOfDirectory(
                    at: self.cacheDirectoryURL,
                    includingPropertiesForKeys: [.fileSizeKey]
                )
                
                for fileURL in contents {
                    if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                       let fileSize = resourceValues.fileSize {
                        totalSize += Int64(fileSize)
                    }
                }
                
                return .success(totalSize)
            } catch {
                print("❌ 캐시 크기 계산 실패: \(error)")
                return .failure(.diskRemoveFailure)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func createCacheDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: cacheDirectoryURL.path) {
            do {
                try fileManager.createDirectory(
                    at: cacheDirectoryURL,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
                print("📁 캐시 디렉토리 생성됨: \(cacheDirectoryURL.path)")
            } catch {
                print("❌ 캐시 디렉토리 생성 실패: \(error)")
            }
        }
    }
    
    private func cacheFilePath(forKey key: NSCacheKey<Key>) -> URL {
        let keyString = String(describing: key.value.diskKeyPath)
        let safeFileName = keyString
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
            .replacingOccurrences(of: "?", with: "_")
            .replacingOccurrences(of: "&", with: "_")
        
        return cacheDirectoryURL.appendingPathComponent(safeFileName)
    }
    
    private func writeData(with data: Data, to filePath: URL) throws {
        do {
            try data.write(to: filePath, options: .atomic)
        } catch {
            throw StorageError.diskWriteFailure
        }
    }
    
    private func loadData(from filePath: URL) throws -> Data {
        do {
            return try Data(contentsOf: filePath)
        } catch {
            throw StorageError.notFound
        }
    }
}

// MARK: - Encode, Decode
extension DiskStorage {
    private func encodeObject(with object: Encodable) throws -> Data {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            return try encoder.encode(object)
        } catch {
            throw StorageError.encodingFailed
        }
    }
    
    private func decodeObject(with data: Data) throws -> NSCacheObject<Object> {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(NSCacheObject<Object>.self, from: data)
        } catch {
            throw StorageError.decodingFailed
        }
    }
}

// MARK: - Result Extension
extension Result {
    public func flatMap<NewSuccess>(_ transform: (Success) -> Result<NewSuccess, Failure>) -> Result<NewSuccess, Failure> {
        switch self {
        case .success(let value):
            return transform(value)
        case .failure(let error):
            return .failure(error)
        }
    }
}
