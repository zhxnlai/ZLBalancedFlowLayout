//
//  ViewController.swift
//  ZLBalancedFlowLayoutDemo
//
//  Created by Zhixuan Lai on 12/23/14.
//  Copyright (c) 2014 Zhixuan Lai. All rights reserved.
//

import UIKit

class ViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    let Repetition = 1
    let NumSections = 2
    var images = [UIImage]()
    
    let cellIdentifier = "cell"
    let headerIdentifier = "header"
    let footerIdentifier = "footer"

    override init(collectionViewLayout layout: UICollectionViewLayout!) {
        super.init(collectionViewLayout: layout)
        
        var paths = NSBundle.mainBundle().pathsForResourcesOfType("jpg", inDirectory: "") as Array<String>
        for path in paths {
            if let image = UIImage(contentsOfFile: path) {
                images.append(image)
            }
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "ZLBalancedFlowLayout"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Refresh, target: self , action: Selector("refreshButtonAction:"))
        
        collectionView?.backgroundColor = UIColor.whiteColor()
        collectionView?.registerClass(UICollectionViewCell.classForCoder(), forCellWithReuseIdentifier: cellIdentifier)
        collectionView?.registerClass(LabelCollectionReusableView.classForCoder(), forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: headerIdentifier)
        collectionView?.registerClass(LabelCollectionReusableView.classForCoder(), forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: footerIdentifier)
    }

    // MARK: - Action
    func refreshButtonAction(sender:UIBarButtonItem) {
        self.collectionView?.reloadData()
    }
    
    // MARK: - UICollectionViewDataSource
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return NumSections
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count*Repetition
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        var cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellIdentifier, forIndexPath: indexPath) as UICollectionViewCell
        var imageView = UIImageView(image: imageForIndexPath(indexPath))
        imageView.contentMode = .ScaleAspectFill
        cell.backgroundView = imageView
        cell.clipsToBounds = true
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        var view = LabelCollectionReusableView(frame: CGRectZero)
        switch (kind) {
        case UICollectionElementKindSectionHeader:
            view = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionHeader, withReuseIdentifier: headerIdentifier, forIndexPath: indexPath) as LabelCollectionReusableView
            view.textLabel.text = "Header"
        case UICollectionElementKindSectionFooter:
            view = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionFooter, withReuseIdentifier: footerIdentifier, forIndexPath: indexPath) as LabelCollectionReusableView
            view.textLabel.text = "Footer"
        default:
            view.textLabel.text = "N/A"
        }
        return view
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        var size = imageForIndexPath(indexPath).size
        var percentWidth = CGFloat(140 - arc4random_uniform(80))/100
        return CGSize(width: size.width*percentWidth/4, height: size.height/4)
    }
    
    // MARK: - ()
    func imageForIndexPath(indexPath:NSIndexPath) -> UIImage {
        return images[indexPath.item%images.count]
    }
}

