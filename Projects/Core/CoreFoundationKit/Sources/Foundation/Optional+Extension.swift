//
//  Any+Extension.swift
//  CoreFoundationKit
//
//  Created by 이숭인 on 5/22/25.
//

import Foundation

extension Optional {
    /// Optional이 nil인지 확인하는 프로퍼티
     var isNil: Bool {
         return self == nil
     }
     
     /// Optional이 nil이 아닌지 확인하는 프로퍼티
     var isNotNil: Bool {
         return self != nil
     }
}
