//
//  LinkAddTask.swift
//  LinkSavingFeature
//
//  Created by 이숭인 on 6/14/25.
//

import Foundation
import Combine
import LinkSavingInterface
import CoreFoundationKit

final class LinkAddTask: TaskType {
    typealias EventType = LinkItemEvent
    
    private var cancellables = Set<AnyCancellable>()
    let eventSubject = PassthroughSubject<LinkItemEvent, Never>()
    var eventPublisher: AnyPublisher<LinkItemEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }
    
    private let localRepository: LinkItemLocalRepository
    private let linkItem: LinkItem
    
    init(
        linkItem: LinkItem,
        localRepository: LinkItemLocalRepository
    ) {
        self.linkItem = linkItem
        self.localRepository = localRepository
    }
    
    deinit {
        print("LinkAddTask deinit")
    }
    
    func execute() {
        print("execute LinkAddTask")
        localRepository.add(with: linkItem)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.eventSubject.send(.addFailed(error.localizedDescription))
                }
            } receiveValue: { [weak self] linkItem in
                self?.taskFinish(event: .addCompleted)
            }
            .store(in: &cancellables)
    }
}
