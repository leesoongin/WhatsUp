//
//  NavigationBarApplicable.swift
//  LinkSavingFeature
//
//  Created by 이숭인 on 5/3/25.
//

import UIKit
import CombineCocoa
import RxSwift
import RxCocoa

public protocol NavigationBarApplicable where Self: UIViewController {
    var navigationBarType: NavigationBarType { get }
    var leftButtonItems: [NavigationBarButtonType] { get }
    var rightButtonItems: [NavigationBarButtonType] { get }
    func initNavigationBar()
    func handleNavigationButtonAction(with identifier: String)
}

//MARK: - Default Value
extension NavigationBarApplicable {
    public var navigationBarType: NavigationBarType {
        .standard(
            title: nil,
            titleColor: .black,
            backgroundColor: .systemBackground,
            hasShadow: false
        )
    }
    public var leftButtonItems: [NavigationBarButtonType] { [] }
    public var rightButtonItems: [NavigationBarButtonType] { [] }
    
    public func handleNavigationButtonAction(with identifier: String) { }
}

extension NavigationBarApplicable {
    public func initNavigationBar() {
        navigationItem.title = navigationBarType.title
        
        initAppearance()
        
        navigationItem.hidesBackButton = true
        
        navigationItem.leftBarButtonItems = buttonItems(for: leftButtonItems)
        navigationItem.rightBarButtonItems = buttonItems(for: rightButtonItems)
    }
    
    private func initAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = navigationBarType.backgroundColor
        appearance.shadowColor = .clear
        appearance.shadowImage = navigationBarType.hasShadow ? UIColor.gray.as1pxImage() : UIColor.clear.as1pxImage()
        appearance.titlePositionAdjustment = .zero
        appearance.titleTextAttributes = [
            .foregroundColor: navigationBarType.titleColor,
            .font: navigationBarType.font
        ]
        
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
    }
    
    private func buttonItems(for items: [NavigationBarButtonType]) -> [UIBarButtonItem] {
        let items = items.map { buttonType in
            let item: FlexibleBarButtonItem = buttonType.makeBarButtonItem()
            
            item.button.rx.tap
                .throttle(.seconds(1), latest: false, scheduler: MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    self?.handleNavigationButtonAction(with: buttonType.identifier)
                })
                .disposed(by: item.rx.disposeBag)

            return item
        }
        
        return items
    }
}

extension UIColor {
    func as1pxImage() -> UIImage {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        setFill()
        UIGraphicsGetCurrentContext()?.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return image
    }
}
