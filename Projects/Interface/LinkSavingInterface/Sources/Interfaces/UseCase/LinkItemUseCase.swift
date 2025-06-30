//
//  LinkItemUseCase.swift
//  LinkSavingInterface
//
//  Created by 이숭인 on 5/27/25.
//

import Foundation
import Combine
import CoreFoundationKit

public enum LinkItemEvent {
    case addCompleted
    case addFailed(String)
    
    case fetchCompleted([LinkItem])
    case fetchFailed(String)
    
    case removeAllCompleted
    case removeAllFailed(String)
}

public protocol LinkItemUseCase {
    init(localRepository: LinkItemLocalRepository)
    
    var eventPublisher: AnyPublisher<LinkItemEvent, Never> { get }
    var localRepository: LinkItemLocalRepository { get }
    var taskExecutor: TaskExecutor<LinkItemEvent> { get }

    func fetchLinkItems()
    func addLinkItem(with linkItem: LinkItem)
    func readLinkItem(at primaryKey: String)
    func removeLinkItem(at primaryKey: String)
    func removeAllLinkItems()
}
