//
//  NavigationBarType.swift
//  LinkSavingFeature
//
//  Created by 이숭인 on 5/2/25.
//

import UIKit

public extension NavigationBarButtonType {
    var identifier: String {
        switch self {
        case .text(let identifier, _, _, _):
            return identifier
        case .image(let identifier, _, _, _):
            return identifier
        case .backText(let identifier, _, _, _, _):
            return identifier
        case .backImage(let identifier, _, _, _, _):
            return identifier
        }
    }
    
    func makeBarButtonItem() -> FlexibleBarButtonItem {
        switch self {
        case .text(_, let title, let color, let font):
            return FlexibleBarButtonItem(title: title, tintColor: color, font: font)
        case .image(_, let image, let color, let renderingMode):
            return FlexibleBarButtonItem(image: image, tintColor: color, renderingMode: renderingMode)
        case .backText(_, let title, let color, let font, _):
            return FlexibleBarButtonItem(title: title, tintColor: color, font: font)
        case .backImage(_, let image, let color, let renderingMode, _):
            return FlexibleBarButtonItem(image: image, tintColor: color, renderingMode: renderingMode)
        }
    }
}

