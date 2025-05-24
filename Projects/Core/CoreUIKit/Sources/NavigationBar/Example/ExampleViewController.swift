//
//  ExampleViewController.swift
//  CoreFoundationKit
//
//  Created by 이숭인 on 5/7/25.
//

import UIKit
import Combine
import SnapKit

extension ExampleViewController {
    private enum Constants {
        enum NavigationBar {
            static let title: String = "Title"
            static let backButtonTitle: String = "뒤로가기"
        }
        
        enum Identifier {
            static let backButton: String = "navigation_back_button"
            static let savedButton: String = "navigation_saved_button"
            static let shareButton: String = "navigation_share_button"
            static let moreButton: String = "navigation_more_button"
        }
    }
}

public final class ExampleViewController: UIViewController {
    let sampleView = UIView()
    private var cancellables = Set<AnyCancellable>()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLayout()
        initNavigationBar()
    }
    
    private func setupLayout() {
        view.addSubview(sampleView)
        view.backgroundColor = .white
        
        sampleView.backgroundColor = .systemBlue
        sampleView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(150)
        }
    }
}

extension ExampleViewController: NavigationBarApplicable {
    public var navigationBarType: NavigationBarType {
        .standard(
            title: Constants.NavigationBar.title,
            titleColor: .systemMint,
            font: UIFont.systemFont(ofSize: 18, weight: .bold),
            backgroundColor: .systemPurple,
            hasShadow: true
        )
    }
    
    public var leftButtonItems: [NavigationBarButtonType] {
        [
            .backText(
                identifier: Constants.Identifier.backButton,
                title: Constants.NavigationBar.backButtonTitle,
                color: .black,
                font: .systemFont(ofSize: 18, weight: .medium),
                enableAutoClose: true
            )
        ]
    }
    
    public var rightButtonItems: [NavigationBarButtonType] {
        [
            .image(
                identifier: Constants.Identifier.moreButton,
                image: UIImage(systemName: "ellipsis"),
                color: .systemRed,
                renderingMode: .alwaysTemplate
            ),
            .image(
                identifier: Constants.Identifier.shareButton,
                image: UIImage(systemName: "square.and.arrow.up"),
                color: .systemTeal,
                renderingMode: .alwaysTemplate
            ),
            .image(
                identifier: Constants.Identifier.savedButton,
                image: UIImage(systemName: "bookmark.fill"),
                color: .systemBlue,
                renderingMode: .alwaysTemplate
            ),
        ]
    }
    
    public func handleNavigationButtonAction(with identifier: String) {
        switch identifier {
        case Constants.Identifier.backButton:
            print("back button")
        case Constants.Identifier.shareButton:
            print("share 이벤트")
        case Constants.Identifier.savedButton:
            print("saved 이벤트")
        case Constants.Identifier.moreButton:
            print("more 이벤트")
        default:
            break
        }
    }
}
