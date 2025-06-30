//
//  LinkItemUseCaseImpl.swift
//  LinkSavingFeature
//
//  Created by 이숭인 on 5/27/25.
//

import Foundation
import LinkSavingInterface
import CoreFoundationKit
import Combine
import CombineCocoa
import CombineExt

//TODO: Reactive 방식, Concurrency 방식으로. 만들고 무엇이 나을지 한번 확인해보자
final class LinkItemUseCaseImpl: LinkItemUseCase {
    private var cancellables = Set<AnyCancellable>()
    let localRepository: LinkItemLocalRepository
    let asyncLocalRepository = AsyncLinkItemLocalRepositoryImpl(asyncDatabaseBuilder: LinkItemAsyncDatabaseBuilder())
    
    let taskExecutor = TaskExecutor<LinkItemEvent>()
    
    var eventPublisher: AnyPublisher<LinkItemEvent, Never> {
        taskExecutor.eventPublisher
    }
   
    init(
        localRepository: LinkItemLocalRepository
    ) {
        self.localRepository = localRepository
    }
    
    deinit {
        taskExecutor.completeExecution()
    }
    
    func fetchLinkItems() {
        taskExecutor.register {
            fetchAllLinkItemsSerialGroup()
        }
        
        taskExecutor.executeTasks()
    }
    
    func addLinkItem(with linkItem: LinkItem) {
        taskExecutor.register {
            createLinkItemSerialGroup(linkItem: linkItem)
        }
        
        taskExecutor.executeTasks()
        
        Task {
            try await asyncLocalRepository.add(with: linkItem)
        }
    }
    
    func readLinkItem(at primaryKey: String) { }
    
    func removeLinkItem(at primaryKey: String) { }
    
    func removeAllLinkItems() {
        taskExecutor.register {
            removeAllLinkItemsSerialGroup()
        }
        
        taskExecutor.executeTasks()
    }
}

// MARK: - Task Factory
extension LinkItemUseCaseImpl {
    private func makeAddTask(linkItem: LinkItem) -> LinkAddTask {
        LinkAddTask(linkItem: linkItem, localRepository: localRepository)
    }
    
    private func makeFetchTask() -> LinkFetchTask {
        LinkFetchTask(localRepository: localRepository)
    }
    
    private func makeRemoveAllTask() -> LinkRemoveAllTask {
        LinkRemoveAllTask(localRepository: localRepository)
    }
}
    
// MARK: - Make TaskGroup
extension LinkItemUseCaseImpl {
    private func createLinkItemSerialGroup(linkItem: LinkItem) -> SerialTaskGroup<LinkItemEvent> {
        return SerialTaskGroup {
            makeAddTask(linkItem: linkItem)
            makeFetchTask()
        }
    }
    
    private func fetchAllLinkItemsSerialGroup() -> SerialTaskGroup<LinkItemEvent> {
        return SerialTaskGroup {
            makeFetchTask()
        }
    }
    
    private func removeAllLinkItemsSerialGroup() -> SerialTaskGroup<LinkItemEvent> {
        return SerialTaskGroup {
            makeRemoveAllTask()
            makeFetchTask()
        }
    }
}
