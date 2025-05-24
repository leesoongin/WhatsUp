//
//  Project.swift
//  ProjectDescriptionHelpers
//
//  Created by 이숭인 on 5/24/25.
//

import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeCoreModule(
    target: .coreDatabase,
    dependencies: [
        .thirdParty(target: .realmSwift)
    ]
)
