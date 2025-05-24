//
//  TaskGroup.swift
//  CoreFoundationKit
//
//  Created by yeonhwas on 11/13/24.
//  Copyright © 2024 YeonHwaS. All rights reserved.
//

import Foundation
import Combine

public protocol TaskGroup<EventType>: TaskType {
    var eventPublisher: AnyPublisher<EventType, Never> { get }
    func execute()
}
