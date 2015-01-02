//
//  ZLLazyBalancedFlowLayout.swift
//  ZLLazyBalancedFlowLayoutDemo
//
//  Created by Zhixuan Lai on 12/20/14.
//  Copyright (c) 2014 Zhixuan Lai. All rights reserved.
//

import UIKit

class ZLBalancedFlowLayout: UICollectionViewFlowLayout {
    /// The ideal row height of items in the grid
    var rowHeight: CGFloat = 120 {
        didSet {
            invalidateLayout()
        }
    }
    
    /// The option to enforce the ideal row height by changing the aspect ratio of the item if necessary.
    var enforcesRowHeight: Bool = false {
        didSet {
            invalidateLayout()
        }
    }
    
    private var headerFrames = [CGRect](), footerFrames = [CGRect]()
    private var itemFrames = [[CGRect]](), itemOriginYs = [[CGFloat]]()
    private var contentSize = CGSizeZero
    
    // TODO: shouldInvalidateLayoutForBoundsChange

    // MARK: - UICollectionViewLayout
    override func prepareLayout() {
        resetItemFrames()
        contentSize = CGSizeZero
        
        if let collectionView = self.collectionView {
            contentSize = scrollDirection == .Vertical ?
                CGSize(width: collectionView.bounds.width - collectionView.contentInset.left - collectionView.contentInset.right, height: 0) :
                CGSize(width: 0, height: collectionView.bounds.size.height - collectionView.contentInset.top - collectionView.contentInset.bottom)
            
            for (var section = 0; section < collectionView.numberOfSections();section++) {
                headerFrames.append(self.collectionView(collectionView, frameForHeader: true, inSection: section, updateContentSize: &contentSize))
                
                let (frames, originYs) = self.collectionView(collectionView, framesForItemsInSection: section, updateContentSize: &contentSize)
                itemFrames.append(frames)
                itemOriginYs.append(originYs)
                
                footerFrames.append(self.collectionView(collectionView, frameForHeader: false, inSection: section, updateContentSize: &contentSize))
            }
        }
    }
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [AnyObject]? {
        var layoutAttributes = [UICollectionViewLayoutAttributes]()
        
        if let collectionView = self.collectionView {
            // can be further optimized
            for (var section = 0; section < collectionView.numberOfSections();section++) {
                var sectionIndexPath = NSIndexPath(forItem: 0, inSection: section)
                let headerAttributes = layoutAttributesForSupplementaryViewOfKind(UICollectionElementKindSectionHeader, atIndexPath: sectionIndexPath)
                if headerAttributes.frame.size != CGSizeZero && CGRectIntersectsRect(headerAttributes.frame, rect) {
                    layoutAttributes.append(headerAttributes)
                }
                let footerAttributes = layoutAttributesForSupplementaryViewOfKind(UICollectionElementKindSectionFooter, atIndexPath: sectionIndexPath)
                if footerAttributes.frame.size != CGSizeZero && CGRectIntersectsRect(footerAttributes.frame, rect) {
                    layoutAttributes.append(footerAttributes)
                }
                
                var minY = CGFloat(0), maxY = CGFloat(0)
                if (scrollDirection == .Vertical) {
                    minY = CGRectGetMinY(rect)-CGRectGetHeight(rect)
                    maxY = CGRectGetMaxY(rect)
                } else {
                    minY = CGRectGetMinX(rect)-CGRectGetWidth(rect)
                    maxY = CGRectGetMaxX(rect)
                }
                let lowerIndex = binarySearch(itemOriginYs[section], value: minY)
                let upperIndex = binarySearch(itemOriginYs[section], value: maxY)
                
                for (var item = lowerIndex; item<upperIndex; item++) {
                    layoutAttributes.append(self.layoutAttributesForItemAtIndexPath(NSIndexPath(forItem: item, inSection: section)))
                }
            }
        }
        return layoutAttributes
    }
    
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes! {
        var attributes = super.layoutAttributesForItemAtIndexPath(indexPath)
        attributes.frame = itemFrames[indexPath.section][indexPath.row]
        return attributes
    }
    
    override func layoutAttributesForSupplementaryViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes! {
        var attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: elementKind, withIndexPath: indexPath)
        
        switch (elementKind) {
        case UICollectionElementKindSectionHeader:
            attributes.frame = headerFrames[indexPath.section]
        case UICollectionElementKindSectionFooter:
            attributes.frame = footerFrames[indexPath.section]
        default:
            return nil
        }
        // If there is no header or footer, we need to return nil to prevent a crash from UICollectionView private methods.
        if(CGRectIsEmpty(attributes.frame)) {
            return nil;
        }
        
        return attributes
    }
    
    override func collectionViewContentSize() -> CGSize {
        return contentSize
    }

    // MARK: - UICollectionViewLayout Helpers
    private func collectionView(collectionView:UICollectionView, frameForHeader isForHeader:Bool, inSection section:Int, inout updateContentSize contentSize:CGSize) -> CGRect {
        var size = referenceSizeForHeader(isForHeader, inSection: section), frame = CGRectZero
        if (scrollDirection == .Vertical) {
            frame = CGRect(x: 0, y: contentSize.height, width: CGRectGetWidth(collectionView.bounds), height: size.height);
            contentSize = CGSize(width: contentSize.width, height: contentSize.height+size.height)
        } else {
            frame = CGRect(x: contentSize.width, y: 0, width: size.width, height: CGRectGetHeight(collectionView.bounds));
            contentSize = CGSize(width: contentSize.width+size.width, height: contentSize.height)
        }
        return frame
    }
    
    private func collectionView(collectionView:UICollectionView, framesForItemsInSection section:Int, inout updateContentSize contentSize:CGSize) -> ([CGRect], [CGFloat]) {
        var maxWidth = Float(scrollDirection == .Vertical ? contentSize.width : contentSize.height), widths = [Float]()
        for (var item = 0; item < collectionView.numberOfItemsInSection(section);item++) {
            let itemSize = sizeForItemAtIndexPath(NSIndexPath(forItem: item, inSection: section)),
            ratio = scrollDirection == .Vertical ?
                itemSize.width/itemSize.height :
                itemSize.height/itemSize.width
            widths.append(min(Float(ratio*rowHeight), Float(maxWidth)))
        }
        
        // parition widths
        var partitions = partition(widths, max: Float(maxWidth))
        
        let minimumInteritemSpacing = minimumInteritemSpacingForSection(section),
        minimumLineSpacing = minimumLineSpacingForSection(section),
        inset = insetForSection(section)
        var framesInSection = [CGRect](), originYsInSection = [CGFloat](),
        origin = scrollDirection == .Vertical ?
            CGPoint(x: inset.left, y: contentSize.height+inset.top) :
            CGPoint(x: contentSize.width+inset.left, y: inset.top)

        for row in partitions {
            // contentWidth/summedWidth
            let innerMargin = Float(CGFloat(row.count-1)*minimumInteritemSpacing),
            outterMargin = scrollDirection == .Vertical ?
                Float(inset.left+inset.right) :
                Float(inset.top+inset.bottom),
            contentWidth = maxWidth - outterMargin - innerMargin,
            widthRatio = CGFloat(contentWidth/row.reduce(0, combine: { (acc, width) -> Float in acc+width })),
            heightRatio = enforcesRowHeight ? 1 : widthRatio
            for width in row {
                let size = scrollDirection == .Vertical ?
                    CGSize(width: CGFloat(width)*widthRatio, height: rowHeight*heightRatio) :
                    CGSize(width: rowHeight*heightRatio, height: CGFloat(width)*widthRatio)
                let frame = CGRect(origin: origin, size: size)
                framesInSection.append(frame)
                if scrollDirection == .Vertical {
                    origin = CGPoint(x: origin.x+frame.width+minimumInteritemSpacing, y: origin.y)
                    originYsInSection.append(origin.y)
                } else {
                    origin = CGPoint(x: origin.x, y: origin.y+frame.height+minimumInteritemSpacing)
                    originYsInSection.append(origin.x)
                }
            }
            if scrollDirection == .Vertical {
                origin = CGPoint(x: inset.left, y: origin.y+framesInSection.last!.height+minimumLineSpacing+inset.bottom)
            } else {
                origin = CGPoint(x: origin.x+framesInSection.last!.width+minimumLineSpacing+inset.right, y: inset.top)
            }
        }
        
        if scrollDirection == .Vertical {
            contentSize = CGSize(width: contentSize.width, height: origin.y)
        } else {
            contentSize = CGSize(width: origin.x, height: contentSize.height)
        }
        
        return (framesInSection, originYsInSection)
    }
    
    private func resetItemFrames() {
        headerFrames = [CGRect]()
        footerFrames = [CGRect]()
        itemFrames = [[CGRect]]()
        itemOriginYs = [[CGFloat]]()
    }
    
    // MARK: - Delegate Helpers
    private func referenceSizeForHeader(isForHeader: Bool, inSection section: Int) -> CGSize {
        if let collectionView = self.collectionView {
            if let delegate = collectionView.delegate? as? UICollectionViewDelegateFlowLayout {
                var size:CGSize? = nil
                if isForHeader {
                    size = delegate.collectionView?(collectionView, layout: self, referenceSizeForHeaderInSection: section)
                } else {
                    size = delegate.collectionView?(collectionView, layout: self, referenceSizeForFooterInSection: section)
                }
                if let size = size {
                    return size
                }
            }
        }
        if isForHeader {
            return headerReferenceSize
        } else {
            return footerReferenceSize
        }
    }
    
    private func minimumLineSpacingForSection(section: Int) -> CGFloat {
        if let collectionView = self.collectionView {
            if let delegate = collectionView.delegate? as? UICollectionViewDelegateFlowLayout {
                if let minimumLineSpacing = delegate.collectionView?(collectionView, layout: self, minimumLineSpacingForSectionAtIndex: section) {
                    return minimumLineSpacing
                }
            }
        }
        return minimumLineSpacing
    }
    
    private func minimumInteritemSpacingForSection(section: Int) -> CGFloat {
        if let collectionView = self.collectionView {
            if let delegate = collectionView.delegate? as? UICollectionViewDelegateFlowLayout {
                if let minimumInteritemSpacing = delegate.collectionView?(collectionView, layout: self, minimumInteritemSpacingForSectionAtIndex: section) {
                    return minimumInteritemSpacing
                }
            }
        }
        return minimumInteritemSpacing
    }
    
    private func sizeForItemAtIndexPath(indexPath: NSIndexPath) -> CGSize {
        if let collectionView = self.collectionView {
            if let delegate = collectionView.delegate? as? UICollectionViewDelegateFlowLayout {
                if let size = delegate.collectionView?(collectionView, layout: self, sizeForItemAtIndexPath:indexPath) {
                    return size
                }
            }
        }
        return itemSize
    }
    
    private func insetForSection(section: Int) -> UIEdgeInsets {
        if let collectionView = self.collectionView {
            if let delegate = collectionView.delegate? as? UICollectionViewDelegateFlowLayout {
                if let inset = delegate.collectionView?(collectionView, layout: self, insetForSectionAtIndex: section) {
                    return inset
                }
            }
        }
        return sectionInset
    }
    
    // MARK: - ()
    private func binarySearch<T: Comparable>(array: Array<T>, value:T) -> Int{
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
    
    // parition the widths in to rows using dynamic programming O(n^2)
    private func partition(values: [Float], max:Float) -> [[Float]] {
        var numValues = values.count
        
        // matrix of panelty, i: from, j: to
        var slacks = [[Float]](count:numValues+1, repeatedValue: [Float](count:numValues+1, repeatedValue: Float.infinity))
        for (var i=0; i<=numValues; i++) {
            slacks[i][i] = max
            for (var j=i+1; j<=numValues; j++) {
                var slack = slacks[i][j-1]-values[j-1]
                if slack>=0 {
                    slacks[i][j] = slack
                } else {
                    break
                }
            }
        }
        
        // build up values of optimal solutions
        var opt = [Float](count: numValues+1, repeatedValue: 0)
        for (var j=1;j<=numValues;j++) {
            var minVal = Float.infinity
            for (var i=j;i>=0;i--) {
                var slack = slacks[i][j]*slacks[i][j]
                if slack > max*max {
                    break
                }
                minVal = min(minVal, slack+opt[i])
            }
            opt[j] = minVal
        }
        
        // traceback the optimal solution
        var solution = findSolution(slacks, opt: opt, upTo: numValues)
        if solution.last != numValues {
            solution.append(numValues)
        }
        
        // partition widths using the optimal solution
        var partitions = [[Float]](), start = 0
        for end in solution {
            if start != end {
                partitions.append([Float](values[Range(start: start, end: end)]))
            }
            start = end
        }
        
        return partitions
    }
    
    // traceback solution
    private func findSolution(slacks:[[Float]], opt: [Float], upTo n:Int) -> [Int] {
        if n<=1 {
            return []
        } else {
            var minVal = Float.infinity, minIndex = 0
            var curVals = [Float]()
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
