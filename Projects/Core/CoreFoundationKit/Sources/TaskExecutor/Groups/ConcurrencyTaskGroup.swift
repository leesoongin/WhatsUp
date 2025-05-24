//
//  ConcurrencyTaskGroup.swift
//  CoreFoundationKit
//
//  Created by yeonhwas on 11/13/24.
//  Copyright © 2024 YeonHwaS. All rights reserved.
//

import Foundation
import Combine

public final class ConcurrencyTaskGroup<EventType>: TaskGroup {
    private var cancellables = Set<AnyCancellable>()
    private var tasks: [any TaskType<EventType>]
    private var remainingTasks: Int

    public let eventSubject = PassthroughSubject<EventType, Never>()
    public var eventPublisher: AnyPublisher<EventType, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    public init(@TaskTypeBuilder<EventType> _ tasks: () -> [any TaskType<EventType>]) {
        self.tasks = tasks()
        self.remainingTasks = self.tasks.count
    }

    public func execute() {
        tasks.forEach { task in
            task.eventPublisher
                .sink(receiveCompletion: { [weak self] _ in
                    guard let self else { return }
                    self.remainingTasks -= 1
                    if self.remainingTasks == 0 {
                        self.eventSubject.send(completion: .finished)
                    }
                }, receiveValue: { [weak self] event in
                    self?.eventSubject.send(event)
                })
                .store(in: &cancellables)

            task.execute()
        }
    }
}
