//
//  Example.swift
//  CoreFoundationKit
//
//  Created by 이숭인 on 5/24/25.
//

import Foundation
import RealmSwift
import Combine


// MARK: - Default Implementation



// MARK: - Example Models

class ContentItem: Object, DatabaseEntity {
    @Persisted var id: String = UUID().uuidString
    @Persisted var viewed: Bool = false
    @Persisted var url: String = ""
    @Persisted var thumbnail: String = ""
    @Persisted var title: String = ""
    @Persisted var itemDescription: String = ""
    @Persisted var category: String = ""
    @Persisted var memo: String = ""
    @Persisted var time: Date = Date()
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    var primaryKey: String {
        return id
    }
    
    convenience init(
        url: String,
        title: String,
        description: String,
        category: String,
        memo: String = ""
    ) {
        self.init()
        self.url = url
        self.title = title
        self.itemDescription = description
        self.category = category
        self.memo = memo
        self.time = Date()
    }
}

class UserProfile: Object, DatabaseEntity {
    @Persisted var userId: String = UUID().uuidString
    @Persisted var name: String = ""
    @Persisted var email: String = ""
    @Persisted var createdAt: Date = Date()
    
    override static func primaryKey() -> String? {
        return "userId"
    }
    
    var primaryKey: String {
        return userId
    }
}

// MARK: - Concrete Database Builders

struct ContentDatabaseBuilder: DatabaseBuilder {
    typealias Entity = ContentItem
    
    // Custom configuration if needed
    var realmConfiguration: Realm.Configuration {
        var config = Realm.Configuration.defaultConfiguration
        config.schemaVersion = 1
        return config
    }
}

struct UserDatabaseBuilder: DatabaseBuilder {
    typealias Entity = UserProfile
}

// MARK: - Database Container

class DatabaseContainer {
    static let shared = DatabaseContainer()
    
    private let contentBuilder: ContentDatabaseBuilder
    private let userBuilder: UserDatabaseBuilder
    
    private init() {
        self.contentBuilder = ContentDatabaseBuilder()
        self.userBuilder = UserDatabaseBuilder()
    }
    
    func contentDatabase() -> ContentDatabaseBuilder {
        return contentBuilder
    }
    
    func userDatabase() -> UserDatabaseBuilder {
        return userBuilder
    }
}

// MARK: - Service Layer Examples

class ContentService {
    private let database: ContentDatabaseBuilder
    private var cancellables = Set<AnyCancellable>()
    
    init(container: DatabaseContainer = .shared) {
        self.database = container.contentDatabase()
    }
    
    // MARK: - Combine API Usage
    func saveContent(url: String, title: String, description: String, category: String) -> AnyPublisher<ContentItem, DatabaseError> {
        let content = ContentItem(
            url: url,
            title: title,
            description: description,
            category: category
        )
        
        return database.create(content)
    }
    
    func getAllContent() -> AnyPublisher<[ContentItem], DatabaseError> {
        return database.readAll()
    }
    
    func searchContent(by category: String) -> AnyPublisher<[ContentItem], DatabaseError> {
        let predicate = NSPredicate(format: "category == %@", category)
        return database.query(predicate)
    }
    
    func observeAllContent() -> AnyPublisher<[ContentItem], DatabaseError> {
        return database.observe()
    }
    
    // MARK: - Async/Await API Usage
    
    func asyncSaveContent(url: String, title: String, description: String, category: String) async throws -> ContentItem {
        let content = ContentItem(
            url: url,
            title: title,
            description: description,
            category: category
        )
        
        return try await database.asyncCreate(content)
    }
    
    func asyncGetAllContent() async throws -> [ContentItem] {
        return try await database.asyncReadAll()
    }
    
    func asyncSearchContent(by category: String) async throws -> [ContentItem] {
        let predicate = NSPredicate(format: "category == %@", category)
        return try await database.asyncQuery(predicate)
    }
    
    func asyncMarkAsViewed(contentId: String) async throws -> ContentItem {
        guard let content = try await database.asyncRead(primaryKey: contentId) else {
            throw DatabaseError.entityNotFound
        }
        
        content.viewed = true
        return try await database.asyncUpdate(content)
    }
    
    // MARK: - Batch Operations
    
    func asyncImportContent(_ items: [ContentItem]) async throws -> [ContentItem] {
        return try await database.asyncBatchCreate(items)
    }
    
    func asyncDeleteMultipleContent(_ ids: [String]) async throws {
        try await database.asyncBatchDelete(ids)
    }
}

// MARK: - ViewModel Example

class ContentViewModel: ObservableObject {
    @Published var contentItems: [ContentItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let contentService: ContentService
    private var cancellables = Set<AnyCancellable>()
    
    init(contentService: ContentService = ContentService()) {
        self.contentService = contentService
        setupObservers()
    }
    
    private func setupObservers() {
        // 실시간 데이터 관찰 (Combine)
        contentService.observeAllContent()
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] items in
                    self?.contentItems = items
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Combine 방식
    
    func loadAllContentUsingCombine() {
        isLoading = true
        
        contentService.getAllContent()
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] items in
                    self?.contentItems = items
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Async/Await 방식
    
    @MainActor
    func loadAllContentUsingAsync() async {
        isLoading = true
        
        do {
            let items = try await contentService.asyncGetAllContent()
            self.contentItems = items
            self.isLoading = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
    
    @MainActor
    func addContentUsingAsync(title: String, description: String, url: String, category: String) async {
        do {
            let savedContent = try await contentService.asyncSaveContent(
                url: url,
                title: title,
                description: description,
                category: category
            )
            print("Content saved: \(savedContent.title)")
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    func searchContentUsingAsync(category: String) async {
        isLoading = true
        
        do {
            let items = try await contentService.asyncSearchContent(by: category)
            self.contentItems = items
            self.isLoading = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
}

// MARK: - Usage Examples

/*
 === Combine 방식 사용 예시 ===
 
 let container = DatabaseContainer.shared
 let contentDB = container.contentDatabase()
 
 // 저장
 contentDB.create(newContent)
     .sink(receiveCompletion: { _ in }, receiveValue: { savedContent in
         print("Saved: \(savedContent.title)")
     })
     .store(in: &cancellables)
 
 // 조회
 contentDB.readAll()
     .sink(receiveCompletion: { _ in }, receiveValue: { contents in
         print("Found \(contents.count) items")
     })
     .store(in: &cancellables)
 
 // 실시간 관찰
 contentDB.observe()
     .sink(receiveCompletion: { _ in }, receiveValue: { contents in
         // UI 업데이트
     })
     .store(in: &cancellables)
 
 === Async/Await 방식 사용 예시 ===
 
 // 저장
 let savedContent = try await contentDB.asyncCreate(newContent)
 print("Saved: \(savedContent.title)")
 
 // 조회
 let contents = try await contentDB.asyncReadAll()
 print("Found \(contents.count) items")
 
 // 배치 작업
 let importedContents = try await contentDB.asyncBatchCreate(contentList)
 print("Imported \(importedContents.count) items")
 */
