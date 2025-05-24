//
//  NavigationBarType.swift
//  CoreFoundationKit
//
//  Created by 이숭인 on 5/7/25.
//

import UIKit

public enum NavigationBarType {
    case standard(
        title: String?,
        titleColor: UIColor,
        font: UIFont = .systemFont(ofSize: 18, weight: .medium),
        backgroundColor: UIColor,
        hasShadow: Bool
    )
}

public extension NavigationBarType {
    var title: String? {
        switch self {
        case .standard(let title, _, _, _, _):
            return title
        }
    }

    var titleColor: UIColor {
        switch self {
        case .standard(_, let color, _, _, _):
            return color
        }
    }
    
    var font: UIFont {
        switch self {
        case .standard(_, _, let font, _, _):
            return font
        }
    }
    
    var backgroundColor: UIColor {
        switch self {
        case .standard(_, _, _,let backgroundColor, _):
            return backgroundColor
        }
    }
    
    var hasShadow: Bool {
        switch self {
        case .standard(_, _, _, _, let hasShadow):
            return hasShadow
        }
    }
}
