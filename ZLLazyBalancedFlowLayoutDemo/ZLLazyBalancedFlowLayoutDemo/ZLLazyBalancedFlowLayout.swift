//
//  ZLLazyBalancedFlowLayout.swift
//  ZLLazyBalancedFlowLayoutDemo
//
//  Created by Zhixuan Lai on 12/20/14.
//  Copyright (c) 2014 Zhixuan Lai. All rights reserved.
//

import UIKit

protocol ZLLazyBalancedFlowLayoutDelegate : UICollectionViewDelegateFlowLayout {
    
}

class ZLLazyBalancedFlowLayout: UICollectionViewFlowLayout {
    var rowHeight: CGFloat = 150
    var scalesItemToFill: Bool = true
    var headerSize: CGFloat = 30
    var footerSize: CGFloat = 30
//    var sectionInset: UIEdgeInsets = UIEdgeInsetsZero
    
    
    var itemFrames: Array<Array<CGRect>> = Array<Array<CGRect>>()
    var contentSize: CGSize = CGSizeZero
    
    override func prepareLayout() {
        super.prepareLayout()
        
        resetItemFrames()
        
        var contentHeight:CGFloat = 0
        
        var maxWidth = Float(self.collectionView!.frame.size.width)
        var minWidth = maxWidth/4

        var maxAspectRatio = maxWidth/Float(rowHeight)
        if let collectionView = self.collectionView {
            for (var section = 0; section < collectionView.numberOfSections();section++) {
                var delegate:UICollectionViewDelegateFlowLayout = collectionView.delegate as UICollectionViewDelegateFlowLayout
                var headerSize = delegate.collectionView?(collectionView, layout: self, referenceSizeForHeaderInSection: section)
                
                var aspectRatios = Array<Float>()
                var sizes = Array<CGSize>()
                var normalizedWidths = Array<Float>()
                for (var item = 0; item < collectionView.numberOfItemsInSection(section);item++) {
                    var indexPath = NSIndexPath(forItem: item, inSection: section)
                    var itemSize = delegate.collectionView!(collectionView, layout: self, sizeForItemAtIndexPath: indexPath)
                    sizes.append(itemSize)
                    
                    var aspectRatio = Float(itemSize.width/itemSize.height)
                    aspectRatios.append(aspectRatio)
                    
                    var normalizedWidth = min(aspectRatio*Float(rowHeight), Float(maxWidth))
//                    var normalizedWidth = min(Float(itemSize.width), Float(maxWidth))
                    normalizedWidths.append(normalizedWidth)
                }
                
                println("max ar \(maxWidth) clamped ar \(normalizedWidths)")

                var partitions = self.partition(normalizedWidths, max: Float(maxWidth))
                
                println("partition \(partitions)")
                
                
                
                var framesInSection = Array<CGRect>()
                
                var index = 0
                var origin = CGPointZero;
                for (var i = 0;i<partitions.count;i++) {
                    var row = partitions[i]
                    var summedWidth = row.reduce(0, combine: { (acc, e) -> Float in
                        acc+e
                    })
                    
                    var ratio = CGFloat(Float(maxWidth)/summedWidth)
                    println("ratio \(ratio)")

                    var actualRowHeight:CGFloat = 0
                    for (var j = 0;j<row.count;j++) {
                        var col = row[j]
                        var width = CGFloat(aspectRatios[index])*rowHeight
                        var height = rowHeight
                        sizes[index] = CGSize(width: width*ratio, height: height*ratio)
                        
                        actualRowHeight = height*ratio
                        
                        println("actual rowHeight: \(actualRowHeight)")
                        println("size: \(sizes[index])")
                        
                        
                        var frame = CGRect(origin: origin, size: sizes[index])
                        framesInSection.append(frame)
                        
                        index++
                        
                        origin = CGPoint(x: origin.x+width*ratio, y: origin.y)

                    }
                    
                    origin = CGPoint(x: 0, y: origin.y+actualRowHeight)

                    println("bbbb")

                    
                
                    
                }
                contentHeight += origin.y+framesInSection.last!.size.height
                
                println("frames: \(framesInSection)")
                
                
                itemFrames.append(framesInSection)
            }
            
            contentSize = CGSize(width: CGFloat(maxWidth), height: contentHeight)
        }
    }
    
    override func collectionViewContentSize() -> CGSize {
        return self.contentSize
    }
    func resetItemFrames() {
        itemFrames = Array<Array<CGRect>>()
    }
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [AnyObject]? {
//        var attributes = super.layoutAttributesForElementsInRect(rect) as Array<UICollectionViewLayoutAttributes>
//        return attributes.map { (attribute) -> UICollectionViewLayoutAttributes in
//            if attribute.representedElementKind == nil {
//                attribute.frame = self.layoutAttributesForItemAtIndexPath(attribute.indexPath).frame
//            }
//            return attribute
//        }
        
        var attributes = Array<UICollectionViewLayoutAttributes>()
        
        if let collectionView = self.collectionView {
            for (var section = 0; section < collectionView.numberOfSections();section++) {
                for (var item = 0; item < collectionView.numberOfItemsInSection(section);item++) {
                    if CGRectIntersectsRect(rect, itemFrames[section][item]) {
                        attributes.append(self.layoutAttributesForItemAtIndexPath(NSIndexPath(forItem: item, inSection: section)))
                    }
                }
            }
        }
        return attributes
    }
    
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes! {
        var attributes = super.layoutAttributesForItemAtIndexPath(indexPath)
        var frame = attributes.frame
        
//        if (attributes.frame.origin.x <= self.sectionInset.left) {
//            return attributes
//        }
        
        var numItems = collectionView?.numberOfItemsInSection(indexPath.section)
//        if indexPath.item == 0 {
//            frame.origin.x = self.sectionInset.left
//            
//        }
        
        var i = indexPath.item
        var attributesInRow = Array<UICollectionViewLayoutAttributes>()
        var accScale:CGFloat = 0
        var framesInRow = Array<CGRect>()
        
//        while i<numItems {
//            var curAttributes = super.layoutAttributesForItemAtIndexPath(NSIndexPath(forItem: i, inSection: indexPath.section))
//            if (attributes.frame.origin.y > curAttributes.frame.origin.y) {
//                // new row
//                break
//            } else {
//                var aspectRatio = attributes.frame.size.width/attributes.frame.size.height
//                var newWidth = rowHeight/aspectRatio
//                curAttributes.frame = CGRect(origin: curAttributes.frame.origin, size: CGSize(width: newWidth, height: rowHeight))
//                attributesInRow.append(curAttributes)
//            }
//            i++
//        }
        
        
        for attr in attributesInRow {
            
        }

//        var aspectRatio = frame.size.width/frame.size.height
//        var newWidth = rowHeight/aspectRatio
//        frame = CGRect(origin: attributes.frame.origin, size: CGSize(width: newWidth*2, height: rowHeight))

        attributes.frame = itemFrames[indexPath.section][indexPath.row]
        return attributes
    }
    
    func partition(values: Array<Float>, max:Float) -> Array<Array<Float>> {
        var numValues = values.count
        var slacks = Array<Array<Float>>()
        for (var i=0; i<=numValues; i++) {
            var row = Array<Float>()
            for (var j=0; j<=numValues; j++) {
                var slack:Float = 0
                for (var k=i; k<j; k++) {
                    slack+=values[k]
                }
                if slack>max {
                    slack = Float.infinity
                } else {
                    slack = max - slack
                }
                row.append(slack)
            }
            slacks.append(row)
        }
        var opt = Array<Float>()
        opt.append(0)
        for (var j=1;j<=numValues;j++) {
            var minVal = Float.infinity
            
            for (var i=0;i<j;i++) {
                //                println("from \(i) to \(j) slacks \(slacks[i][j]) opt: \(opt)")
                minVal = min(minVal, slacks[i][j]+opt[i])
            }
            opt.append(minVal)
        }
        var solution = findSolution(slacks, opt: opt, upTo: numValues)
        var partitions = Array<Array<Float>>()
        var lastI = 0
        for i in solution {
            partitions.append(Array<Float>(values[Range(start: lastI, end: i)]))
            lastI = i
        }
        partitions.append(Array<Float>(values[Range(start: lastI, end: numValues)]))
        return partitions
    }
    
    func findSolution(slacks:Array<Array<Float>>, opt: Array<Float>, upTo n:Int) -> Array<Int> {
        if n<=1 {
            return []
        } else {
            var minVal = Float.infinity
            var minIndex = 0
            var curVals = Array<Float>()
            for (var i=0;i<n;i++) {
                slacks[i].count
                var curVal = slacks[i][n]+opt[i]
                curVals.append(curVal)
                if minVal > curVal {
                    minVal = curVal
                    minIndex = i
                }
            }
            return findSolution(slacks, opt: opt, upTo: minIndex)+[minIndex]
        }
    }
    

}
