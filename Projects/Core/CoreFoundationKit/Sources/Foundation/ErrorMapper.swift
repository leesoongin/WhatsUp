//
//  ErrorMapper.swift
//  CoreDatabase
//
//  Created by 이숭인 on 5/31/25.
//

import Foundation

public protocol ErrorMapper {
    associatedtype Input: Error
    associatedtype Output: Error
    
    func map(_ error: Input) -> Output
}
