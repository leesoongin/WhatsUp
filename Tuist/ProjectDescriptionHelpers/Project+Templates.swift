//
//  Project+Templates.swift
//  WhatsUpManifests
//
//  Created by 이숭인 on 4/29/25.
//

import ProjectDescription

extension Project {
    public static let depolymentTarget: String = "16.0"
    public static let appName: String = "WhatsUp"
    public static let bundleID: String = "WhatsUp"
    
    public static func makeAppModule(
        name: String,
        dependencies: [TargetDependency] = []
    ) -> Project {
        return Project(
            name: name,
            targets: [
                .makeAppTarget(
                    name: name,
                    dependencies: dependencies
                )
            ]
        )
    }
    
    public static func makeCoreModule(
        target: Module.Core,
        dependencies: [TargetDependency] = []
    ) -> Project {
        return Project(
            name: target.rawValue,
            targets: [
                .makeFeatureTarget(
                    name: target.rawValue,
                    dependencies: dependencies
                )
            ]
        )
    }
    
    public static func makeFeatureModule(
        target: Module.Feature,
        dependencies: [TargetDependency] = []
    ) -> Project {
        return Project(
            name: target.rawValue,
            targets: [
                .makeFeatureTarget(
                    name: target.rawValue,
                    dependencies: dependencies
                )
            ]
        )
    }
    
    public static func makeInterfaceModule(
        target: Module.Interface,
        dependencies: [TargetDependency]
    ) -> Project {
        return Project(
            name: target.rawValue,
            targets: [
                .makeInterfaceTarget(
                    name: target.rawValue,
                    dependencies: dependencies
                )
            ]
        )
    }
    
    public static func makeTestsModule(
        target: Module.Tests,
        dependencies: [TargetDependency]
    ) -> Project {
        return Project(
            name: target.rawValue,
            targets: [
                .makeFeatureTestsTarget(
                    name: target.rawValue,
                    dependencies: dependencies
                )
            ]
        )
    }
}

