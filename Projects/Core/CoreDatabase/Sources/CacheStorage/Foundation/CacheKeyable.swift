//
//  CacheKeyable.swift
//  MedicalFinder
//
//  Created by 이숭인 on 12/13/24.
//  Copyright © 2024 vivaino.mediFinder. All rights reserved.
//

import Foundation

public protocol CacheKeyable: Hashable {
    var diskKeyPath: String { get }
}

