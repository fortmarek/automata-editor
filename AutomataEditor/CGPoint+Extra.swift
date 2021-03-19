import Foundation
import CoreGraphics

extension CGPoint {
    func distance(from other: CGPoint) -> CGFloat {
        pow(other.x - x, 2) + pow(other.y - y, 2)
    }
}

extension Array where Element == CGPoint {
    func closestPoint(from point: CGPoint) -> CGPoint {
        reduce((CGPoint.zero, CGFloat.infinity)) { acc, current in
            let currentDistance = current.distance(from: point)
            return currentDistance < acc.1 ? (current, currentDistance) : acc
        }
        .0
    }
    
    func furthestPoint(from point: CGPoint) -> CGPoint {
        reduce((CGPoint.zero, -CGFloat.infinity)) { acc, current in
            let currentDistance = current.distance(from: point)
            return currentDistance > acc.1 ? (current, currentDistance) : acc
        }
        .0
    }
    
    func center() -> CGPoint {
        let (sumX, sumY, count): (CGFloat, CGFloat, CGFloat) = reduce((CGFloat(0), CGFloat(0), CGFloat(0))) { acc, current in
            (acc.0 + current.x, acc.1 + current.y, acc.2 + 1)
        }
        return CGPoint(x: sumX / count, y: sumY / count)
    }
    
    func radius(with center: CGPoint) -> CGFloat {
        let sumDistance = reduce(0) { acc, current in
            acc + abs(center.x - current.x) + abs(center.y - current.y)
        }
        return sumDistance / CGFloat(count)
    }
}

