//
//  Package.swift
//  WhatsUpManifests
//
//  Created by 이숭인 on 4/29/25.
//

import PackageDescription

let package = Package(
    name: "Purithm",
    dependencies: [
        .package(url: "https://github.com/SnapKit/SnapKit.git", .upToNextMajor(from: "5.0.1")),
        .package(url: "https://github.com/devxoul/Then", exact: "3.0.0"),
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.9.0"),
        .package(url: "https://github.com/realm/realm-swift.git", from: "10.50.0"),
        .package(url: "https://github.com/CombineCommunity/CombineExt.git", exact: "1.8.1"),
        .package(url: "https://github.com/CombineCommunity/CombineCocoa.git", exact: "0.4.1"),
        .package(url: "https://github.com/ReactiveX/RxSwift.git", exact: "6.7.0"),
        .package(url: "https://github.com/RxSwiftCommunity/RxSwiftExt.git", exact: "6.2.1"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", exact: "7.11.0"),
        .package(url: "https://github.com/Moya/Moya.git", from: "15.0.0")
    ]
)

