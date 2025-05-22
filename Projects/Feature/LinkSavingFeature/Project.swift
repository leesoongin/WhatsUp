//
//  Project.swift
//  WhatsUpManifests
//
//  Created by 이숭인 on 4/29/25.
//

import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeFeatureModule(
    target: .linkSavingFeature,
    dependencies: [
        .core(target: .coreCommonKit),
        .core(target: .coreUIKit),
        .interface(target: .linkSavingInterface)
    ]
)

