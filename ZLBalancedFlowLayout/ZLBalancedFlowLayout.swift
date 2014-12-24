//
//  ZLLazyBalancedFlowLayout.swift
//  ZLLazyBalancedFlowLayoutDemo
//
//  Created by Zhixuan Lai on 12/20/14.
//  Copyright (c) 2014 Zhixuan Lai. All rights reserved.
//

import UIKit

class ZLLazyBalancedFlowLayout: UICollectionViewFlowLayout {
    var rowHeight: CGFloat = 150
    var scalesItemToFill: Bool = true
    var headerSize: CGFloat = 30
    var footerSize: CGFloat = 30
    
    var itemFrames = [[CGRect]]()
    var itemOriginYs = [CGFloat]()
    var contentSize: CGSize = CGSizeZero
    
    override func prepareLayout() {
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
                
                NSLog("before getting item info")
                
                for (var item = 0; item < collectionView.numberOfItemsInSection(section);item++) {
                    var indexPath = NSIndexPath(forItem: item, inSection: section)
                    var itemSize = delegate.collectionView!(collectionView, layout: self, sizeForItemAtIndexPath: indexPath)
                    sizes.append(itemSize)
                    
                    var aspectRatio = Float(itemSize.width/itemSize.height)
                    aspectRatios.append(aspectRatio)
                    
                    var normalizedWidth = min(aspectRatio*Float(rowHeight), Float(maxWidth))
                    normalizedWidths.append(normalizedWidth)
                }
                
                NSLog("before partition")
                
                var partitions = self.partition(normalizedWidths, max: Float(maxWidth))
                
                println("partition \(partitions)")
                
                NSLog("after partition")
                
                var framesInSection = Array<CGRect>()
                
                var index = 0
                var origin = CGPointZero;
                for (var i = 0;i<partitions.count;i++) {
                    var row = partitions[i]
                    var summedWidth = row.reduce(0, combine: { (acc, e) -> Float in
                        acc+e
                    })
                    
                    var ratio = CGFloat(Float(maxWidth)/summedWidth)
                    
                    var actualRowHeight:CGFloat = 0
                    for (var j = 0;j<row.count;j++) {
                        var col = row[j]
                        var width = CGFloat(aspectRatios[index])*rowHeight
                        var height = rowHeight
                        sizes[index] = CGSize(width: width*ratio, height: height*ratio)
                        
                        actualRowHeight = height*ratio
                        
                        var frame = CGRect(origin: origin, size: sizes[index])
                        framesInSection.append(frame)
                        
                        index++
                        
                        
                        itemOriginYs.append(origin.y)
                        
                        origin = CGPoint(x: origin.x+width*ratio, y: origin.y)
                        
                    }
                    
                    origin = CGPoint(x: 0, y: origin.y+actualRowHeight)
                }
                contentHeight += origin.y
                
                NSLog("after rescale")
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
        var attributes = Array<UICollectionViewLayoutAttributes>()
        
        if let collectionView = self.collectionView {
            for (var section = 0; section < collectionView.numberOfSections();section++) {
                var lowerIndex = binarySearch(itemOriginYs, value: CGRectGetMinY(rect)-CGRectGetHeight(rect))
                var upperIndex = binarySearch(itemOriginYs, value: CGRectGetMaxY(rect))
                
                for (var item = lowerIndex; item<upperIndex; item++) {
                    attributes.append(self.layoutAttributesForItemAtIndexPath(NSIndexPath(forItem: item, inSection: section)))
                }
            }
        }
        return attributes
    }
    
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes! {
        var attributes = super.layoutAttributesForItemAtIndexPath(indexPath)
        var frame = attributes.frame
        attributes.frame = itemFrames[indexPath.section][indexPath.row]
        return attributes
    }
    
    func binarySearch<T: Comparable>(array: Array<T>, value:T) -> Int{
        var imin=0, imax=array.count
        while imin<imax {
            var imid = imin+(imax-imin)/2
            
            if array[imid] < value {
                imin = imid+1
            } else {
                imax = imid
            }
        }
        return imin
    }
    
    func partition(values: Array<Float>, max:Float) -> Array<Array<Float>> {
        var numValues = values.count
        
        NSLog("before init slacks")
        var row = [Float](count:numValues+1, repeatedValue: Float.infinity)
        var slacks = [[Float]](count:numValues+1, repeatedValue: row)
        
        NSLog("before compute slacks")
        
        var n = 0, m = 0
        for (var i=0; i<=numValues; i++) {
            slacks[i][i] = max
            for (var j=i+1; j<=numValues; j++) {
                var slack = slacks[i][j-1]-values[j-1]
                m++
                if slack<0 {
                    break
                } else {
                    slacks[i][j] = slack
                    n++
                }
            }
        }

        NSLog("slacks took %i steps m: %i", n, m)
        
//        for row in slacks {
//            println("\(row)")
//
//        }
        
        NSLog("before compute opt")
        
        n=0
        var opt = [Float](count: numValues+1, repeatedValue: 0)
        //        opt.append(0)
        for (var j=1;j<=numValues;j++) {
            var minVal = Float.infinity
            
            for (var i=j;i>=0;i--) {
                var slack = slacks[i][j]*slacks[i][j]
                if slack > max*max {
                    break
                }
                // println("from \(i) to \(j) slacks \(slacks[i][j]) opt: \(opt)")
                minVal = min(minVal, slack+opt[i])
                n++
            }
            opt[j] = minVal
        }
        NSLog("opt took %i steps", n)
        
        NSLog("before find solution")
        
        var solution = findSolution(slacks, opt: opt, upTo: numValues)
        
        NSLog("after find solution")
        
        var partitions = Array<Array<Float>>()
        var lastI = 0
        for i in solution {
            if i != lastI {
                partitions.append(Array<Float>(values[Range(start: lastI, end: i)]))
            }
            lastI = i
        }
        if numValues != lastI {
            
            partitions.append(Array<Float>(values[Range(start: lastI, end: numValues)]))
        }
        return partitions
    }
    
    func findSolution(slacks:Array<Array<Float>>, opt: Array<Float>, upTo n:Int) -> Array<Int> {
        if n<=1 {
            return []
        } else {
            var minVal = Float.infinity
            var minIndex = 0
            var curVals = Array<Float>()
            for (var i=n;i>=0;i--) {
                if slacks[i][n] == Float.infinity {
                    break
                }
                
                var curVal = slacks[i][n]*slacks[i][n]+opt[i]
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
