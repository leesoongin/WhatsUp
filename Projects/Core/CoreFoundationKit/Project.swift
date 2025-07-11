//
//  Project.swift
//  ProjectDescriptionHelpers
//
//  Created by 이숭인 on 5/7/25.
//

import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeCoreModule(
    target: .coreFoundationKit,
    dependencies: [
        .thirdParty(target: .combineCocoa),
        .thirdParty(target: .rxSwift),
        .thirdParty(target: .rxCocoa),
        .thirdParty(target: .realm),
        .thirdParty(target: .realmSwift)
    ]
)
