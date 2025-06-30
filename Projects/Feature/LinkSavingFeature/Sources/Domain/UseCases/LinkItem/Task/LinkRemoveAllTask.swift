//
//  LinkRemoveAllTask.swift
//  LinkSavingFeature
//
//  Created by 이숭인 on 6/14/25.
//

import Foundation
import Combine
import LinkSavingInterface
import CoreFoundationKit

final class LinkRemoveAllTask: TaskType {
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
        print("LinkRemoveAllTask deinit")
    }
    
    func execute() {
        print("execute LinkRemoveAllTask")
        localRepository.removeAll()
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.eventSubject.send(.removeAllFailed(error.localizedDescription))
                }
            } receiveValue: { [weak self] linkItems in
                self?.taskFinish(event: .removeAllCompleted)
            }
            .store(in: &cancellables)
    }
}
