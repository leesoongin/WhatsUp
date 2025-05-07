//
//  Project.swift
//  ProjectDescriptionHelpers
//
//  Created by 이숭인 on 5/7/25.
//

import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeCoreModule(
    target: .coreCommonKit,
    dependencies: [
        .thirdParty(target: .snapKit),
        .thirdParty(target: .then),
        .thirdParty(target: .combineCocoa),
        .thirdParty(target: .rxSwift),
        .thirdParty(target: .rxCocoa)
    ]
)
