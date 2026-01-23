//
//  RankingCarouselLayout.swift
//  Filo
//
//  Created by 이상민 on 01/23/26.
//

import UIKit

final class RankingCarouselLayout: UICollectionViewFlowLayout {
    private static let badgeInset: CGFloat = 8
    private static let badgeFont: UIFont = UIFont.Mulggeol.title1 ?? UIFont.systemFont(ofSize: 20)
    private static var defaultBadgeOverflow: CGFloat {
        (badgeFont.lineHeight + (badgeInset * 2)) / 2
    }
    
    let lift: CGFloat = 24
    let drop: CGFloat = 24
    let badgeOverflow: CGFloat = RankingCarouselLayout.defaultBadgeOverflow
    
    var requiredHeight: CGFloat{
        itemSize.height + sectionInset.top + sectionInset.bottom
    }
    
    override init() {
        super.init()
        scrollDirection = .horizontal
        let spacing = 8.0
        let width = (UIScreen.main.bounds.width - (2 * spacing)) / 1.8
        let height = width * 1.8
        itemSize = CGSize(width: width, height: height)
        sectionInset = UIEdgeInsets(top: lift, left: 20, bottom: drop + badgeOverflow, right: 20)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        true
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attributes = super.layoutAttributesForElements(in: rect),
              let collectionView else { return nil }

        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        let visibleAreas: [(UICollectionViewLayoutAttributes, CGFloat)] = attributes.map { attr in
            let intersection = attr.frame.intersection(visibleRect)
            let area = max(intersection.width, 0) * max(intersection.height, 0)
            return (attr, area)
        }
        let sorted = visibleAreas.sorted { $0.1 > $1.1 }
        let first = sorted.first
        let second = sorted.dropFirst().first
        let firstArea = first?.1 ?? 0
        let secondArea = second?.1 ?? 0
        let total = max(firstArea + secondArea, 1)
        let delta = (firstArea - secondArea) / total
        let threshold: CGFloat = 0.08
        let transition: CGFloat
        if delta >= threshold {
            transition = 1
        } else if delta <= -threshold {
            transition = 0
        } else {
            let raw = (delta + threshold) / max(threshold * 2, 0.001)
            let t = min(max(raw, 0), 1)
            transition = t * t * (3 - 2 * t)
        }
        return attributes.map { attr in
            let copied = attr.copy() as! UICollectionViewLayoutAttributes
            let isFirst = copied.indexPath == first?.0.indexPath
            let isSecond = copied.indexPath == second?.0.indexPath
            let yOffset: CGFloat
            if isFirst {
                yOffset = -lift + ((drop + lift) * (1 - transition))
            } else if isSecond {
                yOffset = drop - ((drop + lift) * (1 - transition))
            } else {
                yOffset = drop
            }
            
            copied.transform = CGAffineTransform(translationX: 0, y: yOffset)
            copied.zIndex = isFirst ? 1 : 0
            copied.alpha = 1
            return copied
        }
    }

    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard let collectionView else { return proposedContentOffset }
        let targetRect = CGRect(x: proposedContentOffset.x, y: 0, width: collectionView.bounds.width, height: collectionView.bounds.height)
        guard let attributes = super.layoutAttributesForElements(in: targetRect) else { return proposedContentOffset }
        let centerX = proposedContentOffset.x + collectionView.bounds.width / 2
        let closest = attributes.min(by: { abs($0.center.x - centerX) < abs($1.center.x - centerX) })
        guard let closest else { return proposedContentOffset }
        return CGPoint(x: closest.center.x - collectionView.bounds.width / 2, y: proposedContentOffset.y)
    }
}
