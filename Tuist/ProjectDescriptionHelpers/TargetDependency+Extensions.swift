//
//  TargetDependency+Extensions.swift
//  WhatsUpManifests
//
//  Created by 이숭인 on 4/29/25.
//

import ProjectDescription

public extension TargetDependency {
    static func feature(
        target: Module.Feature
    ) -> TargetDependency {
        return .project(
            target: target.rawValue,
            path: .relativeToRoot("Projects/Feature/\(target.rawValue)")
        )
    }
    
    static func interface(
        target: Module.Interface
    ) -> TargetDependency {
        return .project(
            target: target.rawValue,
            path: .relativeToRoot("Projects/Interface/\(target.rawValue)")
        )
    }
    
    static func core(
        target: Module.Core
    ) -> TargetDependency {
        return .project(
            target: target.rawValue,
            path: .relativeToRoot("Projects/Core/\(target.rawValue)")
        )
    }
    
    static func thirdParty(
        target: Module.ThirdParty,
        condition: PlatformCondition? = nil
    ) -> TargetDependency {
        return .external(
            name: target.rawValue,
            condition: condition)
    }
    
    static func tests(
        target: Module.Tests
    ) -> TargetDependency {
        return .project(
            target: target.rawValue,
            path: .relativeToRoot("Projects/Tests/\(target.rawValue)")
        )
    }
}

