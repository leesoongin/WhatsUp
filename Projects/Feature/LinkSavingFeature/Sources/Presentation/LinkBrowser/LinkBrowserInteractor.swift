//
//  LinkBrowserInteractor.swift
//  LinkSavingFeature
//
//  Created by 이숭인 on 5/27/25.
//

import Foundation
import Combine
import CombineExt
import CoreUIKit
import CoreFoundationKit

import LinkSavingInterface

enum LinkBrowserCommand {
    case fetchLinkItems
    case addLinkItem
    case clearLinkItems
}

protocol LinkBrowserInteractor {
    func process(with command: LinkBrowserCommand)
}

final class LinkBrowserInteractorImpl: LinkBrowserInteractor {
    private let presenter: LinkBrowserPresenter?
    private let router: LinkBrowserRoutingLogic?
    
    private let linkItemUseCase: LinkItemUseCase?
    private var cancellables = Set<AnyCancellable>()
    
    var executor = TaskExecutor<LinkItemEvent>()
    
    init(
        linkItemUseCase: LinkItemUseCase,
        presenter: LinkBrowserPresenter & LinkBrowserPublishable & LinkBrowserRoutingLogic
    ) {
        self.linkItemUseCase = linkItemUseCase
        self.presenter = presenter
        self.router = presenter
        
        bindUseCaseOutput()
    }
    
    func process(with command: LinkBrowserCommand) {
        switch command {
        case .fetchLinkItems:
            fetchItems()
        case .addLinkItem:
            addItem()
        case .clearLinkItems:
            clearItems()
        }
    }
    
    private func fetchItems() {
        linkItemUseCase?.fetchLinkItems()
    }
    
    private func addItem() {
        let linkItem = LinkItem(
            identifier: UUID().uuidString,
            url: "https://www.youtube.com/watch?v=aocFbKmTaZA",
            title: "테스트 유튜브 타이틀",
            content: "테스트 유튜브 컨텐츠",
            thumbnailImageURL: "https://www.youtube.com/watch?v=aocFbKmTaZA",
            memoContent: "메모입니다.",
            categoryIdentifier: "",
            timestamp: Date()
        )
        
        linkItemUseCase?.addLinkItem(with: linkItem)
    }
    
    private func clearItems() {
        linkItemUseCase?.removeAllLinkItems()
    }
}

// MARK: - UseCase Event Bindings
extension LinkBrowserInteractorImpl {
    private func bindUseCaseOutput() {
        linkItemUseCase?.eventPublisher
            .sink(receiveCompletion: { completion in
                print("✅ 모든 작업 완료!")
            }, receiveValue: { [weak self] event in
                switch event {
                case .addCompleted:
                    self?.handleAddCompleted()
                case .addFailed(let message):
                    self?.handleAddFailed(errorMessage: message)
                case .fetchCompleted(let items):
                    self?.transformToLinkItemModels(from: items)
                case .fetchFailed(let message):
                    self?.handleFetchFailed(errorMessage: message)
                case .removeAllCompleted:
                    self?.handleRemoveAllCompleted()
                case .removeAllFailed(let message):
                    self?.handleRemoveAllFailed(errorMessage: message)
                }
            })
            .store(in: &cancellables)
    }
    
    private func handleAddCompleted() {
        print("::: addCompleted")
    }
    
    private func handleAddFailed(errorMessage: String) {
        print("::: addFailed")
    }
    
    private func transformToLinkItemModels(from items: [LinkItem]) {
        print("::: fetchCompleted")
        
        let itemModels = items.map { linkItem in
            LinkBrowseItemComponent(
                identifier: linkItem.identifier,
                title: linkItem.title,
                description: linkItem.content ?? "",
                thumbnailURLString: linkItem.thumbnailImageURL ?? ""
            )
        }
        
        let sectionModel = SectionModel(
            identifier: "linkBrowse_section",
            itemModels: itemModels
        )
        
        presenter?.present(with: .fetchedLinkItems(linkComponents: [sectionModel]))
    }
    
    private func handleFetchFailed(errorMessage: String) {
        print("::: fetchFailed")
    }
    
    private func handleRemoveAllCompleted() {
        print("::: removeAllCompleted")
    }
    
    private func handleRemoveAllFailed(errorMessage: String) {
        print("::: removeAllFailed")
    }
}

//TODO: interactor, presenter 추가 - 1 [x]
//TODO: 에러 처리 핸들러 추가 + presentation 에서 사용할 error 정의가 필요함 - 2 [x]
//TODO: usecase impl에서 Task 만드는거 factory 패턴 적용해서 만들도록? 좀 간단하게 만들 수 있도록 수정 - 3 [x]
//TODO: Concurrency 추가 / CoreDatabase 작업 - 4
//TODO: 실제로 구현한 구현체들을 다른 Feature 모듈에서 어떤식으로 가져가 쓸수 있는지, 그 bridge를 어떻게 구성해야하는지 생각해보자. - 5
//TODO: Mapper 어떻게 하는게 효율적일지? 고민해보자





// 화면전환 routeTo
// 모델 변환 transform
// 성공/에러 처리 handle
