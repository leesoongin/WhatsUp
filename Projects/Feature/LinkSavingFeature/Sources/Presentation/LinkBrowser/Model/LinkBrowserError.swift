//
//  LinkBrowserError.swift
//  LinkSavingFeature
//
//  Created by 이숭인 on 5/31/25.
//

import Foundation
import LinkSavingInterface

//TODO: 더하기 실패했다면, 어떤게 실패했는지 알아야할까? 아니면 그냥 에러메세지를 띄워야할까.
// 둘 다 할 수 있는게 좋을거같음



enum LinkBrowserError: Error {
    case notFound // 어떤걸 찾을 수 없는지? id 값을 받아올까?
    case failedClearLinkItems
    case failedFetchAllItems
    case failedFetchSingleItem // 어떤걸 못가져왔는지 id
    case failedSaveLinkItem //. 어떤걸 못 저장했는지 id
    
    func mapToError(from errorEvent: LinkItemEvent) -> LinkBrowserError {
        switch errorEvent {
        case .addFailed(let errorMessage):
            return .failedSaveLinkItem
        case .fetchFailed(let errorMessage):
            return .failedFetchAllItems
        case .removeAllFailed(let errorMessage):
            return .failedClearLinkItems
        default:
            return .notFound
        }
    }
}
