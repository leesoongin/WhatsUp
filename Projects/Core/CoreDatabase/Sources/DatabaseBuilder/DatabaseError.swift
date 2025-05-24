//
//  DatabaseError.swift
//  CoreFoundationKit
//
//  Created by 이숭인 on 5/24/25.
//

import Foundation

public enum DatabaseError: Error, LocalizedError {
    case realmNotAvailable
    case entityNotFound
    case saveFailed(Error)
    case deleteFailed(Error)
    case queryFailed(Error)
    case migrationFailed(Error)
    case threadSafetyViolation
    case invalidOperation
    
    public var errorDescription: String? {
        switch self {
        case .realmNotAvailable:
            return "데이터베이스에 접근할 수 없습니다."
        case .entityNotFound:
            return "요청한 엔티티를 찾을 수 없습니다."
        case .saveFailed(let error):
            return "저장 실패: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "삭제 실패: \(error.localizedDescription)"
        case .queryFailed(let error):
            return "쿼리 실행 실패: \(error.localizedDescription)"
        case .migrationFailed(let error):
            return "마이그레이션 실패: \(error.localizedDescription)"
        case .threadSafetyViolation:
            return "스레드 안전성 위반이 발생했습니다."
        case .invalidOperation:
            return "유효하지 않은 작업입니다."
        }
    }
}
