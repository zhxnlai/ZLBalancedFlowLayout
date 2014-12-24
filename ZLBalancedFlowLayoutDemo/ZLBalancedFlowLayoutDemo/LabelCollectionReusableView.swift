//
//  LabelCollectionReusableView.swift
//  ZLBalancedFlowLayoutDemo
//
//  Created by Zhixuan Lai on 12/24/14.
//  Copyright (c) 2014 Zhixuan Lai. All rights reserved.
//

import UIKit

class LabelCollectionReusableView: UICollectionReusableView {
    var textLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        backgroundColor = UIColor.lightGrayColor()
        textLabel.textColor = UIColor.blackColor()
        textLabel.textAlignment = .Center
        addSubview(textLabel)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        textLabel.frame = self.bounds
    }
}
