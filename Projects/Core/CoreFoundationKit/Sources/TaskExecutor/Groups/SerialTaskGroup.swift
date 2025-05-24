//
//  SerialTaskGroup.swift
//  CoreFoundationKit
//
//  Created by yeonhwas on 11/13/24.
//  Copyright © 2024 YeonHwaS. All rights reserved.
//

import Foundation
import Combine

public final class SerialTaskGroup<EventType>: TaskGroup {
    private var cancellables = Set<AnyCancellable>()
    private var tasks: [any TaskType<EventType>]

    public let eventSubject = PassthroughSubject<EventType, Never>()
    public var eventPublisher: AnyPublisher<EventType, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    public init(@TaskTypeBuilder<EventType> _ tasks: () -> [any TaskType<EventType>]) {
        self.tasks = tasks()
    }

    public func execute() {
        guard let task = tasks.first else {
            return eventSubject.send(completion: .finished)
        }

        task.eventPublisher
            .sink(receiveCompletion: { [weak self] completion in
                guard case .finished = completion else { return }
                self?.tasks.removeFirst()
                self?.execute()
            }, receiveValue: { [weak self] event in
                self?.eventSubject.send(event)
            })
            .store(in: &cancellables)

        task.execute()
    }
}
