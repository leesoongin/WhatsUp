//
//  TaskType.swift
//  CoreFoundationKit
//
//  Created by yeonhwas on 11/13/24.
//  Copyright © 2024 YeonHwaS. All rights reserved.
//

import Foundation
import Combine

public protocol TaskType<EventType> {
    associatedtype EventType
    var eventSubject: PassthroughSubject<EventType, Never> { get }
    var eventPublisher: AnyPublisher<EventType, Never> { get }
    func execute()
    func taskFinish(event: EventType, continueToNext: Bool)
}

extension TaskType {
    public func taskFinish(event: EventType, continueToNext: Bool = true) {
        eventSubject.send(event)
        if continueToNext {
            eventSubject.send(completion: .finished)
        }
    }
}
