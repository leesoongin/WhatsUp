//
//  LinkBrowseItemComponent.swift
//  LinkSavingFeature
//
//  Created by 이숭인 on 5/27/25.
//

import UIKit
import Combine
import CoreUIKit
import SnapKit
import Then

struct LinkBrowseItemComponent: Component {
    var widthStrategy: ViewWidthStrategy = .fill
    var heightStrategy: ViewHeightStrategy = .adaptive
    
    let identifier: String
    let title: String
    let description: String
    let thumbnailURLString: String
    
    init(
        identifier: String,
        title: String,
        description: String,
        thumbnailURLString: String
    ) {
        self.identifier = identifier
        self.title = title
        self.description = description
        self.thumbnailURLString = thumbnailURLString
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(description)
        hasher.combine(thumbnailURLString)
    }
}

extension LinkBrowseItemComponent {
    typealias ContentType = LinkBrowseItemView
    
    func render(content: ContentType, context: Self, cancellable: inout Set<AnyCancellable>) {
        content.configure(
            title: "타이틀입니다. 엄청 긴 타이틀입니다.아너무길어요",
            description: "설명입니다.설명입니다.설명입니다.설명입니다.설명입니다.설명입니다.설명입니다.설명입니다.설명입니다.설명입니다.설명입니다.설명입니다.설명입니다.설명입니다.설명입니다.설명입니다.설명입니다.설명입니다.설명입니다.설명입니다.",
            thumbnailURLString: context.thumbnailURLString
        )
    }
}

final class LinkBrowseItemView: BaseView {
    private let containerView = UIView()
    
    private let thumbnailImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.backgroundColor = .systemCyan
    }
    private let titleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 16, weight: .bold)
        $0.textColor = .black
    }
    private let descriptionLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .medium)
        $0.textColor = .systemGray
    }
    
    override func setup() {
        super.setup()
    }
    
    override func setupSubviews() {
        addSubview(containerView)
        
        containerView.addSubview(titleLabel)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(thumbnailImageView)
    }
    
    override func setupConstraints() {
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
            make.trailing.lessThanOrEqualTo(thumbnailImageView.snp.leading).offset(-8)
            make.height.equalTo(20)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.equalToSuperview()
            make.trailing.lessThanOrEqualTo(thumbnailImageView.snp.leading).offset(-8)
            make.bottom.lessThanOrEqualToSuperview()
        }
        
        thumbnailImageView.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview()
            make.trailing.equalToSuperview()
            make.width.equalTo(120)
            make.height.equalTo(200)
        }
    }
    
    func configure(
        title: String,
        description: String,
        thumbnailURLString: String
    ) {
        titleLabel.text = title
        descriptionLabel.text = description
        
        
    }
}
