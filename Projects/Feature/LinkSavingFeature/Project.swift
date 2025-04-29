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
        .thirdParty(target: .snapKit),
        .thirdParty(target: .then),
    ]
)

