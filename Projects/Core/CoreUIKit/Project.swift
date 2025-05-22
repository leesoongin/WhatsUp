//
//  Project.swift
//  ProjectDescriptionHelpers
//
//  Created by 이숭인 on 5/22/25.
//

import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeCoreModule(
    target: .coreUIKit,
    dependencies: [
        .thirdParty(target: .snapKit),
        .thirdParty(target: .then),
        .thirdParty(target: .combineCocoa),
        .thirdParty(target: .rxSwift),
        .thirdParty(target: .rxCocoa)
    ]
)
