//
//  LinkBrowserPresenter.swift
//  LinkSavingFeature
//
//  Created by 이숭인 on 5/31/25.
//

import Foundation
import Combine
import CoreUIKit

enum LinkBrowserResponse {
    case fetchedLinkItems(linkComponents: [SectionModelType])
}

protocol LinkBrowserPresenter {
    func present(with response: LinkBrowserResponse)
}

protocol LinkBrowserPublishable {
    var linkItemComponents: CurrentValueSubject<[SectionModelType], Never> { get }
}

protocol LinkBrowserRoutingLogic {
    func routeToA()
}

// MARK: - Handle Response Event
final class LinkBrowserPresenterImpl: LinkBrowserPresenter, LinkBrowserPublishable {
    var linkItemComponents = CurrentValueSubject<[SectionModelType], Never>([])
    
    func present(with response: LinkBrowserResponse) {
        switch response {
        case .fetchedLinkItems(let linkComponents):
            linkItemComponents.send(linkComponents)
        }
    }
}

//MARK: - Route
extension LinkBrowserPresenterImpl: LinkBrowserRoutingLogic {
    func routeToA() {
        
    }
}
