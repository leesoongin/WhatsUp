//
//  Project.swift
//  ProjectDescriptionHelpers
//
//  Created by 이숭인 on 4/29/25.
//

import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeAppModule(
    name: Project.appName,
    dependencies: [
        .feature(target: .linkSavingFeature)
    ]
)
