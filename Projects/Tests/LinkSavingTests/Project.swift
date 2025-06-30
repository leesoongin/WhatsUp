//
//  Project.swift
//  ProjectDescriptionHelpers
//
//  Created by 이숭인 on 6/30/25.
//

import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeTestsModule(
    target: .linkSavingTests,
    dependencies: [
        .interface(target: .linkSavingInterface),
        .feature(target: .linkSavingFeature),
        .thirdParty(target: .quick),
        .thirdParty(target: .nimble)
    ]
)
