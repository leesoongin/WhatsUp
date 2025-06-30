//
//  TaskExecutor.swift
//  CoreFoundationKit
//
//  Created by yeonhwas on 11/13/24.
//  Copyright © 2024 YeonHwaS. All rights reserved.
//

import Foundation
import Combine
import Then

public final class TaskExecutor<EventType>: Then {
    private var cancellables = Set<AnyCancellable>()
    private var taskGroups: [any TaskGroup<EventType>] = []

    private let eventSubject = PassthroughSubject<EventType, Never>()
    public var eventPublisher: AnyPublisher<EventType, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    public init() { }

    public func register(@TaskGroupBuilder<EventType> _ content: () -> [any TaskGroup<EventType>]) {
        self.taskGroups = content()
    }

    public func executeTasks(continueToNext: Bool = true) {
        guard let taskGroup = taskGroups.first else {
//            Log.info("[TaskExecutor] all task finished")
            if !continueToNext {
                eventSubject.send(completion: .finished)
            }
            return
        }

        taskGroup.eventPublisher
            .sink(receiveCompletion: { [weak self] _ in
                self?.taskGroups.removeFirst()
                self?.executeTasks()
            }, receiveValue: { [weak self] event in
                self?.eventSubject.send(event)
            })
            .store(in: &cancellables)

        taskGroup.execute()
    }
    
    public func completeExecution() {
        eventSubject.send(completion: .finished)
    }
}
