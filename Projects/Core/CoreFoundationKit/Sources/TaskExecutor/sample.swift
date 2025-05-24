//
//  sample.swift
//  CoreFoundationKit
//
//  Created by 이숭인 on 5/24/25.
//  Copyright © 2025 YeonHwaS. All rights reserved.
//

import Foundation
import Foundation
import Combine

// MARK: - 1. 이벤트 타입 정의
enum AppEvent {
    case downloadStarted(String)
    case downloadProgress(Float)
    case downloadCompleted(Data)
    case processingStarted
    case processingCompleted(Data)
    case uploadStarted
    case uploadCompleted(URL)
    case error(Error)
}

// MARK: - 2. 기본 Task 구현 예제

// 다운로드 Task
class DownloadTask: TaskType {
    typealias EventType = AppEvent
    
    let eventSubject = PassthroughSubject<AppEvent, Never>()
    var eventPublisher: AnyPublisher<AppEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }
    
    private let url: URL
    
    init(url: URL) {
        self.url = url
    }
    
    func execute() {
        // 다운로드 시작 이벤트
        eventSubject.send(.downloadStarted(url.absoluteString))
        
        // 실제 다운로드 시뮬레이션
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) { [weak self] in
            // 진행률 이벤트
            self?.eventSubject.send(.downloadProgress(0.5))
            
            DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                // 완료 이벤트
                let fakeData = "Downloaded content".data(using: .utf8)!
                self?.taskFinish(event: .downloadCompleted(fakeData))
            }
        }
    }
}

// 이미지 처리 Task
class ImageProcessingTask: TaskType {
    typealias EventType = AppEvent
    
    let eventSubject = PassthroughSubject<AppEvent, Never>()
    var eventPublisher: AnyPublisher<AppEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }
    
    private let imageData: Data
    
    init(imageData: Data) {
        self.imageData = imageData
    }
    
    func execute() {
        eventSubject.send(.processingStarted)
        
        // 이미지 처리 시뮬레이션
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) { [weak self] in
            let processedData = "Processed: \(self?.imageData)".data(using: .utf8)!
            self?.taskFinish(event: .processingCompleted(processedData))
        }
    }
}

// 업로드 Task
class UploadTask: TaskType {
    typealias EventType = AppEvent
    
    let eventSubject = PassthroughSubject<AppEvent, Never>()
    var eventPublisher: AnyPublisher<AppEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }
    
    private let data: Data
    
    init(data: Data) {
        self.data = data
    }
    
    func execute() {
        eventSubject.send(.uploadStarted)
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) { [weak self] in
            let uploadedURL = URL(string: "https://example.com/uploaded/image.jpg")!
            self?.taskFinish(event: .uploadCompleted(uploadedURL))
        }
    }
}

// MARK: - 3. SerialTaskGroup 사용 예제 (순차 실행)

// 이미지 다운로드 후 순차적으로 처리하는 그룹
func createImageProcessingSerialGroup() -> SerialTaskGroup<AppEvent> {
    let imageData = Data() // 예제용 데이터
    
    return SerialTaskGroup {
        DownloadTask(url: URL(string: "https://example.com/image1.jpg")!)
        ImageProcessingTask(imageData: imageData)
        UploadTask(data: imageData)
    }
}

// MARK: - 4. ConcurrencyTaskGroup 사용 예제 (동시 실행)

// 여러 이미지를 동시에 다운로드하는 그룹
func createMultipleDownloadsConcurrentGroup() -> ConcurrencyTaskGroup<AppEvent> {
    return ConcurrencyTaskGroup {
        DownloadTask(url: URL(string: "https://example.com/image1.jpg")!)
        DownloadTask(url: URL(string: "https://example.com/image2.jpg")!)
        DownloadTask(url: URL(string: "https://example.com/image3.jpg")!)
    }
}

// MARK: - 5. TaskExecutor 사용 예제

class ImageSyncService {
    private var cancellables = Set<AnyCancellable>()
    
    func syncImages() {
        // TaskExecutor 생성 및 설정
        let executor = TaskExecutor<AppEvent>().then {
            $0.register {
                // 1. 먼저 여러 이미지를 동시에 다운로드
                createMultipleDownloadsConcurrentGroup()
                
                // 2. 다운로드 완료 후 순차적으로 처리
                createImageProcessingSerialGroup()
                
                // 3. 추가 작업 그룹
                SerialTaskGroup {
                    CleanupTask()
                    NotificationTask()
                }
            }
        }
        
        // 이벤트 구독
        executor.eventPublisher
            .sink(
                receiveCompletion: { completion in
                    print("✅ 모든 작업 완료!")
                },
                receiveValue: { event in
                    switch event {
                    case .downloadStarted(let url):
                        print("⬇️ 다운로드 시작: \(url)")
                    case .downloadProgress(let progress):
                        print("📊 진행률: \(Int(progress * 100))%")
                    case .downloadCompleted:
                        print("✅ 다운로드 완료")
                    case .processingStarted:
                        print("🔄 처리 시작")
                    case .processingCompleted:
                        print("✅ 처리 완료")
                    case .uploadStarted:
                        print("⬆️ 업로드 시작")
                    case .uploadCompleted(let url):
                        print("✅ 업로드 완료: \(url)")
                    case .error(let error):
                        print("❌ 에러: \(error)")
                    }
                }
            )
            .store(in: &cancellables)
        
        // 실행 시작
        executor.executeTasks()
    }
}

// MARK: - 6. 추가 Task 예제

// 정리 작업 Task
class CleanupTask: TaskType {
    typealias EventType = AppEvent
    
    let eventSubject = PassthroughSubject<AppEvent, Never>()
    var eventPublisher: AnyPublisher<AppEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }
    
    func execute() {
        print("🧹 임시 파일 정리 중...")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) { [weak self] in
            print("✅ 정리 완료")
            self?.eventSubject.send(completion: .finished)
        }
    }
}

// 알림 Task
class NotificationTask: TaskType {
    typealias EventType = AppEvent
    
    let eventSubject = PassthroughSubject<AppEvent, Never>()
    var eventPublisher: AnyPublisher<AppEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }
    
    func execute() {
        print("📱 사용자에게 알림 전송 중...")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) { [weak self] in
            print("✅ 알림 전송 완료")
            self?.eventSubject.send(completion: .finished)
        }
    }
}

// MARK: - 7. 조건부 Task 실행 예제

//class ConditionalTaskExample {
//    private var cancellables = Set<AnyCancellable>()
//    private let needsBackup = true
//    private let hasNetworkConnection = true
//    
//    func executeConditionalTasks() {
//        let executor = TaskExecutor<AppEvent>()
//        
//        executor.register {
//            // 항상 실행되는 작업
//            SerialTaskGroup {
//                DownloadTask(url: URL(string: "https://example.com/data.json")!)
//            }
//            
//            // 조건부 실행 (실제로는 Result Builder에서 if문 지원 필요)
//            if needsBackup {
//                SerialTaskGroup {
//                    BackupTask()
//                }
//            }
//            
//            // 네트워크 상태에 따른 분기
//            if hasNetworkConnection {
//                ConcurrencyTaskGroup {
//                    UploadTask(data: Data())
//                    SyncTask()
//                }
//            } else {
//                SerialTaskGroup {
//                    CacheTask()
//                }
//            }
//        }
//        
//        executor.executeTasks()
//    }
//}
//
//// MARK: - 8. 실제 사용 예제
//
//// 사용 방법
//let service = ImageSyncService()
//service.syncImages()
//
//// 출력 예시:
//// ⬇️ 다운로드 시작: https://example.com/image1.jpg
//// ⬇️ 다운로드 시작: https://example.com/image2.jpg
//// ⬇️ 다운로드 시작: https://example.com/image3.jpg
//// 📊 진행률: 50%
//// ✅ 다운로드 완료
//// ⬇️ 다운로드 시작: https://example.com/image1.jpg
//// 📊 진행률: 50%
//// ✅ 다운로드 완료
//// 🔄 처리 시작
//// ✅ 처리 완료
//// ⬆️ 업로드 시작
//// ✅ 업로드 완료: https://example.com/uploaded/image.jpg
//// 🧹 임시 파일 정리 중...
//// ✅ 정리 완료
//// 📱 사용자에게 알림 전송 중...
//// ✅ 알림 전송 완료
//// ✅ 모든 작업 완료!
