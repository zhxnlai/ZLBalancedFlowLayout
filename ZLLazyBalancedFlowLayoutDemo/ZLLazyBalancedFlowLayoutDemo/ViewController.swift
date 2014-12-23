//
//  ViewController.swift
//  ZLLazyBalancedFlowLayoutDemo
//
//  Created by Zhixuan Lai on 12/20/14.
//  Copyright (c) 2014 Zhixuan Lai. All rights reserved.
//

import UIKit

class ViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    let numImages = 24
    var images = Array<UIImage>()
    
    override init(collectionViewLayout layout: UICollectionViewLayout!) {
        super.init(collectionViewLayout: layout)
        
        for (var i=0;i<numImages;i++) {
            let name = NSString(format: "photo-%02d.jpg", i)
            if let image = UIImage(named: name) {
                images.append(image)

            }
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        collectionView?.backgroundColor = UIColor.whiteColor()
        
//        collectionView?.collectionViewLayout = layout
        collectionView?.registerClass(UICollectionViewCell.classForCoder(), forCellWithReuseIdentifier: "cell")
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        var cell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as UICollectionViewCell
        
        cell.backgroundView = UIImageView(image: images[indexPath.item])
        //        cell.backgroundColor = UIColor.redColor().colorWithAlphaComponent(0.5)
        cell.layer.borderColor = UIColor.whiteColor().CGColor
        cell.layer.borderWidth = 1
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
//        var height = CGFloat(30 + arc4random()%40)
//        return CGSize(width: 100, height: height)
        return images[indexPath.item].size
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

