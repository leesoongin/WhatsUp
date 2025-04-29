//
//  SampleViewController.swift
//  LinkSavingFeature
//
//  Created by 이숭인 on 4/29/25.
//

import UIKit
import SnapKit

public final class SampleViewController: UIViewController {
    let sampleView = UIView()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(sampleView)
        view.backgroundColor = .white
        
        sampleView.backgroundColor = .systemBlue
        sampleView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(150)
        }
        
        print("화면 나타남")
    }
}
