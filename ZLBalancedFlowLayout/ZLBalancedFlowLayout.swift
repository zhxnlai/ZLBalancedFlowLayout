//
//  ZLBalancedFlowLayout.swift
//  ZLBalancedFlowLayoutDemo
//
//  Created by Zhixuan Lai on 12/20/14.
//  Copyright (c) 2014 Zhixuan Lai. All rights reserved.
//

import UIKit

public class ZLBalancedFlowLayout: UICollectionViewFlowLayout {
    /// The ideal row height of items in the grid
    public var rowHeight: CGFloat = 100 {
        didSet {
            invalidateLayout()
        }
    }

    /// The option to enforce the ideal row height by changing the aspect ratio of the item if necessary.
    public var enforcesRowHeight: Bool = false {
        didSet {
            invalidateLayout()
        }
    }

    private var headerFrames = [CGRect](), footerFrames = [CGRect]()
    private var itemFrames = [[CGRect]](), itemOriginYs = [[CGFloat]]()
    private var contentSize = CGSizeZero

    // TODO: shouldInvalidateLayoutForBoundsChange

    // MARK: - UICollectionViewLayout
    override public func prepareLayout() {
        resetItemFrames()
        contentSize = CGSizeZero

        if let collectionView = self.collectionView {
            contentSize = scrollDirection == .Vertical ?
                CGSize(width: collectionView.bounds.width - collectionView.contentInset.left - collectionView.contentInset.right, height: 0) :
                CGSize(width: 0, height: collectionView.bounds.size.height - collectionView.contentInset.top - collectionView.contentInset.bottom)

            for section in (0..<collectionView.numberOfSections()) {
                headerFrames.append(self.collectionView(collectionView, frameForHeader: true, inSection: section, updateContentSize: &contentSize))

                let (frames, originYs) = self.collectionView(collectionView, framesForItemsInSection: section, updateContentSize: &contentSize)
                itemFrames.append(frames)
                itemOriginYs.append(originYs)

                footerFrames.append(self.collectionView(collectionView, frameForHeader: false, inSection: section, updateContentSize: &contentSize))
            }
        }
    }

    override public func layoutAttributesForElementsInRect(rect: CGRect) -> [AnyObject]? {
        var layoutAttributes = [UICollectionViewLayoutAttributes]()

        if let collectionView = self.collectionView {
            // can be further optimized
            for section in (0..<collectionView.numberOfSections()) {
                var sectionIndexPath = NSIndexPath(forItem: 0, inSection: section)
                if let headerAttributes = layoutAttributesForSupplementaryViewOfKind(UICollectionElementKindSectionHeader, atIndexPath: sectionIndexPath) where headerAttributes.frame.size != CGSizeZero && CGRectIntersectsRect(headerAttributes.frame, rect) {
                    layoutAttributes.append(headerAttributes)
                }
                if let footerAttributes = layoutAttributesForSupplementaryViewOfKind(UICollectionElementKindSectionFooter, atIndexPath: sectionIndexPath) where footerAttributes.frame.size != CGSizeZero && CGRectIntersectsRect(footerAttributes.frame, rect) {
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

                for item in lowerIndex..<upperIndex {
                    layoutAttributes.append(self.layoutAttributesForItemAtIndexPath(NSIndexPath(forItem: item, inSection: section)))
                }
            }
        }
        return layoutAttributes
    }

    override public func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes! {
        var attributes = super.layoutAttributesForItemAtIndexPath(indexPath)
        attributes.frame = itemFrames[indexPath.section][indexPath.row]
        return attributes
    }

    override public func layoutAttributesForSupplementaryViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes! {
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

    override public func collectionViewContentSize() -> CGSize {
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
        let maxWidth = Float(scrollDirection == .Vertical ? contentSize.width : contentSize.height),
        widths = map(0..<collectionView.numberOfItemsInSection(section), {(item: Int) -> Float in
            let itemSize = self.sizeForItemAtIndexPath(NSIndexPath(forItem: item, inSection: section)),
            ratio = self.scrollDirection == .Vertical ?
                itemSize.width/itemSize.height :
                itemSize.height/itemSize.width
            return min(Float(ratio*self.rowHeight), Float(maxWidth))
        })

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
            widthRatio = CGFloat(contentWidth/row.reduce(0, combine: +)),
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
        if let collectionView = self.collectionView, let delegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout {
            if isForHeader {
                if let size = delegate.collectionView?(collectionView, layout: self, referenceSizeForHeaderInSection: section) {
                    return size
                }
            } else {
                if let size = delegate.collectionView?(collectionView, layout: self, referenceSizeForFooterInSection: section) {
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
        if let collectionView = self.collectionView, delegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout, minimumLineSpacing = delegate.collectionView?(collectionView, layout: self, minimumLineSpacingForSectionAtIndex: section) {
            return minimumLineSpacing
        }
        return minimumLineSpacing
    }

    private func minimumInteritemSpacingForSection(section: Int) -> CGFloat {
        if let collectionView = self.collectionView, delegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout, minimumInteritemSpacing = delegate.collectionView?(collectionView, layout: self, minimumInteritemSpacingForSectionAtIndex: section) {
            return minimumInteritemSpacing
        }
        return minimumInteritemSpacing
    }

    private func sizeForItemAtIndexPath(indexPath: NSIndexPath) -> CGSize {
        if let collectionView = self.collectionView, let delegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout, let size = delegate.collectionView?(collectionView, layout: self, sizeForItemAtIndexPath:indexPath) {
            return size
        }
        return itemSize
    }

    private func insetForSection(section: Int) -> UIEdgeInsets {
        if let collectionView = self.collectionView, delegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout, inset = delegate.collectionView?(collectionView, layout: self, insetForSectionAtIndex: section){
          return inset
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
        if numValues == 0 {
            return []
        }

        var slacks = [[Float]](count: numValues, repeatedValue: [Float](count: numValues, repeatedValue: Float.infinity))
        for var from=0; from<numValues; from++ {
            for var to=from; to<numValues; to++ {
                var slack = to==from ? max-values[to] : slacks[from][to-1]-values[to]
                if slack >= 0 {
                    slacks[from][to] = slack
                } else {
                    break
                }
            }
        }

        // build up values of optimal solutions
        var opt = [Float](count: numValues, repeatedValue: 0)
        opt[0] = pow(slacks[0][0], 2)
        for var to=1; to<numValues; to++ {
            var minVal = Float.infinity
            for var from=0; from<=to; from++ {
                var slack = pow(slacks[from][to], 2)
                if slack > pow(max, 2) {
                    continue
                }
                var opp = (from==0 ? 0 : opt[from-1])
                minVal = min(minVal, slack+opp)
            }
            opt[to] = minVal
        }

        // traceback the optimal solution
        var partitions = [[Float]]()
        findSolution(values, slacks: slacks, opt: opt, to: numValues-1, partitions: &partitions)
        return partitions
    }

    // traceback solution
    private func findSolution(values: [Float], slacks:[[Float]], opt: [Float], to: Int, inout partitions: [[Float]]) {
        if to<0 {
            partitions = partitions.reverse()
        } else {
            var minVal = Float.infinity, minIndex = 0
            for var from=to; from>=0; from-- {
                if slacks[from][to] == Float.infinity {
                    continue
                }

                var curVal = pow(slacks[from][to], 2) + (from==0 ? 0 : opt[from-1])
                if minVal > curVal {
                    minVal = curVal
                    minIndex = from
                }
            }
            partitions.append([Float](values[minIndex...to]))
            findSolution(values, slacks: slacks, opt: opt, to: minIndex-1, partitions: &partitions)
        }
    }

}
