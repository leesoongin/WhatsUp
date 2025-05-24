//
//  TaskGroupBuilder.swift
//  CoreFoundationKit
//
//  Created by yeonhwas on 11/13/24.
//  Copyright © 2024 YeonHwaS. All rights reserved.
//

import Foundation

@resultBuilder
public struct TaskGroupBuilder<T> {
    public static func buildBlock(_ components: any TaskGroup<T>...) -> [any TaskGroup<T>] {
        return components
    }
    
    // 조건문 지원 (if)
    public static func buildOptional(_ components: any TaskGroup<T>...) -> [any TaskGroup<T>] {
        return components
    }
    
    // 조건문 지원 (if-else의 첫 번째 분기)
    public static func buildEither(_ components: any TaskGroup<T>...) -> [any TaskGroup<T>] {
        return components
    }

    // for-in 루프 지원
    public static func buildArray(_ components: any TaskGroup<T>...) -> [any TaskGroup<T>] {
        return components
    }
}
