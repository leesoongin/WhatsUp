//
//  Target+Templates.swift
//  WhatsUpManifests
//
//  Created by 이숭인 on 4/29/25.
//

import ProjectDescription

public extension Target {
    static func makeAppTarget(
        name: String,
        dependencies: [TargetDependency] = []
    ) -> Target {
        return .target(
            name: name,
            destinations: .iOS,
            product: .app,
            bundleId: "com.\(name).app",
            deploymentTargets: .iOS(Project.depolymentTarget),
            infoPlist: .extendingDefault(with: [
                "UILaunchStoryboardName": "LaunchScreen.storyboard",
                "CFBundleShortVersionString": "1.0.0",
                "CFBundleVersion": "1",
                "NSAppTransportSecurity": [ "NSAllowsArbitraryLoads": true ],
                "UIApplicationSceneManifest": [
                    "UISceneConfigurations": [
                        "UIWindowSceneSessionRoleApplication": []
                    ]
                ]
            ]),
            sources: ["Sources/**"],
            dependencies: dependencies
        )
    }
    
    static func makeCoreTarget(
        name: String,
        dependencies: [TargetDependency] = []
    ) -> Target{
        return .target(
            name: name,
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "com.\(name).core",
            deploymentTargets: .iOS(Project.depolymentTarget),
            infoPlist: .default,
            sources: ["Sources/**"],
            dependencies: dependencies
        )
    }
    
    static func makeFeatureTarget(
        name: String,
        dependencies: [TargetDependency] = []
    ) -> Target{
        return .target(
            name: name,
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "com.\(name).feature",
            deploymentTargets: .iOS(Project.depolymentTarget),
            infoPlist: .default,
            sources: ["Sources/**"],
            dependencies: dependencies
        )
    }
    
    static func makeInterfaceTarget(
        name: String,
        dependencies: [TargetDependency] = []
    ) -> Target {
        return .target(
            name: name,
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "com.\(name).interface",
            deploymentTargets: .iOS(Project.depolymentTarget),
            infoPlist: .default,
            sources: ["Sources/**"],
            dependencies: dependencies
        )
    }
    
    static func makeFeatureTestingTarget(
        name: String,
        dependencies: [TargetDependency] = []
    ) -> Target {
        return .target(
            name: name,
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "com.\(name).testing",
            deploymentTargets: .iOS(Project.depolymentTarget),
            infoPlist: .default,
            sources: ["Sources/**"],
            dependencies: dependencies
        )
    }
    
    static func makeFeatureTestsTarget(
        name: String,
        dependencies: [TargetDependency] = []
    ) -> Target {
        return .target(
            name: name,
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.\(name).tests",
            deploymentTargets: .iOS(Project.depolymentTarget),
            infoPlist: .default,
            sources: ["Sources/**"],
            dependencies: dependencies
        )
    }
    
    static func makeFeatureExampleTarget(
        name: String,
        dependencies: [TargetDependency] = []
    ) -> Target {
        return .target(
            name: name,
            destinations: .iOS,
            product: .app,
            bundleId: "com.\(name).example.app",
            deploymentTargets: .iOS(Project.depolymentTarget),
            infoPlist: .default,
            sources: ["Sources/**"],
            dependencies: dependencies
        )
    }

}
