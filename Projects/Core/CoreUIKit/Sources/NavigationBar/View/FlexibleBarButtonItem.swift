//
//  FlexibleBarButtonItem.swift
//  LinkSavingFeature
//
//  Created by 이숭인 on 5/2/25.
//

import UIKit
import Then

public final class FlexibleBarButtonItem: UIBarButtonItem {
    public let button = UIButton()
    
    public init(
        title: String?,
        tintColor: UIColor,
        font: UIFont = UIFont.systemFont(ofSize: 18, weight: .medium)
    ) {
        super.init()
        
        button.do {
            $0.setTitle(title, for: .normal)
            $0.setTitleColor(tintColor, for: .normal)
            $0.titleLabel?.font = font
            let textSize = (title ?? "").size(withAttributes: [
                NSAttributedString.Key.font: font
            ])
            $0.frame = CGRect(origin: .zero, size: CGSize(width: textSize.width + 16, height: 40))
            $0.backgroundColor = .clear
        }
        
        customView = button
    }
    
    public init(image: UIImage?, tintColor: UIColor, renderingMode: UIImage.RenderingMode = .alwaysTemplate) {
        super.init()
        
        button.do {
            $0.tintColor = tintColor
            $0.backgroundColor = .clear
            $0.frame = CGRect(origin: .zero, size: CGSize(width: 40, height: 40))
            $0.setImage(
                image?.withRenderingMode(renderingMode),
                for: .normal
            )
        }
        
        customView = button
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
