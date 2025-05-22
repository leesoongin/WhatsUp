//
//  NavigationBarButtonType.swift
//  LinkSavingFeature
//
//  Created by 이숭인 on 5/3/25.
//


import UIKit

public enum NavigationBarButtonType: Hashable {
    case text(
        identifier: String,
        title: String,
        color: UIColor = .black,
        font: UIFont = .systemFont(ofSize: 18, weight: .medium)
    )
    case image(
        identifier: String,
        image: UIImage?,
        color: UIColor = .black,
        renderingMode: UIImage.RenderingMode = .alwaysTemplate
    )
    case backText(
        identifier: String,
        title: String,
        color: UIColor = .black,
        font: UIFont = .systemFont(ofSize: 18, weight: .medium),
        enableAutoClose: Bool = true
    )
    case backImage(
        identifier: String,
        image: UIImage?,
        color: UIColor = .black,
        renderingMode: UIImage.RenderingMode = .alwaysTemplate,
        enableAutoClose: Bool = true
    )
}
