//
//  Array+Extension.swift
//  CoreFoundationKit
//
//  Created by 이숭인 on 5/22/25.
//

import Foundation

extension Array {
    /// 안전한 배열 접근을 위한 subscript
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
