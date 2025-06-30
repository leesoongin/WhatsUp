//
//  LinkCategoryBrowserViewController.swift
//  LinkSavingFeature
//
//  Created by 이숭인 on 5/7/25.
//

import UIKit
import CoreUIKit
import Combine

//TODO: Coordinator 혹은 이걸 생성해서 외부로 던질 수 있는게 필요함.

public final class LinkBrowserView: BaseView {
    let collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: UICollectionViewFlowLayout()
    )
    
    public override func setup() {
        super.setup()
        
        self.backgroundColor = .white
    }
    
    public override func setupSubviews() {
        addSubview(collectionView)
    }
    
    public override func setupConstraints() {
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

public final class LinkBrowserViewController: ViewController<LinkBrowserView> {
    var cancellables = Set<AnyCancellable>()
    
    private lazy var adapter = CollectionViewAdapter(with: contentView.collectionView)
    
    private let presenter: LinkBrowserPresenter & LinkBrowserPublishable & LinkBrowserRoutingLogic = LinkBrowserPresenterImpl()
    private lazy var interactor: LinkBrowserInteractor = LinkBrowserInteractorImpl(
        linkItemUseCase: LinkItemUseCaseImpl(
            localRepository: LinkItemLocalRepositoryImpl(
                linkItemDatabaseBuilder: LinkItemDatabaseBuilder(),
                errorMapper: DatabaseErrorMapper()
            )
        ),
        presenter: self.presenter
    )
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        initNavigationBar()
        bindActions()
        
        interactor.process(with: .fetchLinkItems)
    }
    
    private func bindActions() {
        presenter.linkItemComponents
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                _ = self?.adapter.receive(items)
            }
            .store(in: &cancellables)
    }
}

//MARK: - Navigation Bar
extension LinkBrowserViewController: NavigationBarApplicable {
    private enum Constants {
        enum Identifier: String {
            case addLinkButton
            case deleteLinkButton
            case clearLinkButton
        }
    }
    
    public var navigationBarType: NavigationBarType {
        .standard(
            title: "Links",
            titleColor: .systemMint,
            font: UIFont.systemFont(ofSize: 18, weight: .bold),
            backgroundColor: .white,
            hasShadow: false
        )
    }
    
    public var rightButtonItems: [NavigationBarButtonType] {
        [
            .image(
                identifier: Constants.Identifier.addLinkButton.rawValue,
                image: UIImage(systemName: "plus.circle"),
                color: .black,
                renderingMode: .alwaysTemplate
            ),
            .image(
                identifier: Constants.Identifier.deleteLinkButton.rawValue,
                image: UIImage(systemName: "trash.circle"),
                color: .black,
                renderingMode: .alwaysTemplate
            ),
            .image(
                identifier: Constants.Identifier.clearLinkButton.rawValue,
                image: UIImage(systemName: "eraser"),
                color: .black,
                renderingMode: .alwaysTemplate
            )
        ]
    }
    
    public func handleNavigationButtonAction(with identifier: String) {
        switch identifier {
        case Constants.Identifier.addLinkButton.rawValue:
            interactor.process(with: .addLinkItem)
        case Constants.Identifier.deleteLinkButton.rawValue:
            break
        case Constants.Identifier.clearLinkButton.rawValue:
            interactor.process(with: .clearLinkItems)
        default:
            break
        }
    }
}

//protocol LinkBrowserErrorHandleable where Self: UIViewController {
//    var cancellables: Set<AnyCancellable> { get set }
//    var errorPublisher: AnyPublisher<Error, Never> { get }
//    
//    func bindErrorHandle()
//}
