//
//  LinkFetchTask.swift
//  LinkSavingFeature
//
//  Created by 이숭인 on 6/14/25.
//

import Foundation
import Combine
import LinkSavingInterface
import CoreFoundationKit

final class LinkFetchTask: TaskType {
    typealias EventType = LinkItemEvent
    
    private var cancellables = Set<AnyCancellable>()
    let eventSubject = PassthroughSubject<LinkItemEvent, Never>()
    var eventPublisher: AnyPublisher<LinkItemEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }
    
    private let localRepository: LinkItemLocalRepository
    
    init(localRepository: LinkItemLocalRepository) {
        self.localRepository = localRepository
    }
    
    deinit {
        print("LinkFetchTask deinit")
    }
    
    func execute() {
        print("execute LinkFetchTask")
        localRepository.loadAll()
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.eventSubject.send(.fetchFailed(error.localizedDescription))
                }
            } receiveValue: { [weak self] linkItems in
                self?.taskFinish(event: .fetchCompleted(linkItems))
            }
            .store(in: &cancellables)
    }
}
