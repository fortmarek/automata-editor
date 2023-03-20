import CoreGraphics
import SwiftUI

extension Path {
    mutating func cycle(
        point: CGPoint,
        center: CGPoint
    ) {
        let vector = Vector(point, center)
        let topPoint = vector.rotated(by: .pi / 11).point(distance: -100, other: point)
        let radius = sqrt(pow(center.x - point.x, 2) + pow(center.y - point.y, 2))
        let finalPoint = Vector(center, point).rotated(by: .pi / 8).point(distance: radius, other: center)
        move(to: point)
        addQuadCurve(
            to: finalPoint,
            control: topPoint
        )

        arrow(startPoint: Vector(topPoint, finalPoint).point(distance: 95, other: topPoint), tipPoint: finalPoint, arrowSpan: 30)
    }
    
    mutating func arrow(
        startPoint: CGPoint,
        tipPoint: CGPoint,
        flexPoint: CGPoint? = nil,
        arrowSpan: CGFloat = 60
    ) {
        let vector = Vector(flexPoint ?? startPoint, tipPoint)
        let anchorPoint = vector.point(distance: -arrowSpan / 3, other: tipPoint)
        let perpendicularVector = vector.rotated(by: .pi / 2)
        let topPoint = perpendicularVector.point(distance: -arrowSpan / 2, other: anchorPoint)
        let bottomPoint = perpendicularVector.point(distance: arrowSpan / 2, other: anchorPoint)

        move(to: startPoint)
        if let flexPoint = flexPoint {
            hermiteSpline(for: [startPoint, flexPoint, tipPoint], closed: false)
        } else {
            addLine(to: tipPoint)
        }
        move(to: tipPoint)
        addLine(to: topPoint)
        move(to: tipPoint)
        addLine(to: bottomPoint)
        move(to: bottomPoint)
    }
    
    // Partly taken from: https://stackoverflow.com/a/34583708/4975152
    mutating func hermiteSpline(for points: [CGPoint], closed: Bool) {
        guard points.count > 1 else { return }
        let numberOfCurves = closed ? points.count : points.count - 1

        var previousPoint: CGPoint? = closed ? points.last : nil
        var currentPoint:  CGPoint  = points[0]
        var nextPoint:     CGPoint? = points[1]

        move(to: currentPoint)

        for index in 0 ..< numberOfCurves {
            let endPt = nextPoint!

            var mx: CGFloat
            var my: CGFloat

            if previousPoint != nil {
                mx = (nextPoint!.x - currentPoint.x) * 0.5 + (currentPoint.x - previousPoint!.x)*0.5
                my = (nextPoint!.y - currentPoint.y) * 0.5 + (currentPoint.y - previousPoint!.y)*0.5
            } else {
                mx = (nextPoint!.x - currentPoint.x) * 0.5
                my = (nextPoint!.y - currentPoint.y) * 0.5
            }

            let ctrlPt1 = CGPoint(x: currentPoint.x + mx / 3.0, y: currentPoint.y + my / 3.0)

            previousPoint = currentPoint
            currentPoint = nextPoint!
            let nextIndex = index + 2
            if closed {
                nextPoint = points[nextIndex % points.count]
            } else {
                nextPoint = nextIndex < points.count ? points[nextIndex % points.count] : nil
            }

            if nextPoint != nil {
                mx = (nextPoint!.x - currentPoint.x) * 0.5 + (currentPoint.x - previousPoint!.x) * 0.5
                my = (nextPoint!.y - currentPoint.y) * 0.5 + (currentPoint.y - previousPoint!.y) * 0.5
            }
            else {
                mx = (currentPoint.x - previousPoint!.x) * 0.5
                my = (currentPoint.y - previousPoint!.y) * 0.5
            }

            let ctrlPt2 = CGPoint(x: currentPoint.x - mx / 3.0, y: currentPoint.y - my / 3.0)

            addCurve(to: endPt, control1: ctrlPt1, control2: ctrlPt2)
        }
    }
}

extension Array where Element == CGPoint {
    static func circle(
        center: CGPoint,
        radius: CGFloat
    ) -> Self {
        stride(from: CGFloat(0), to: 362, by: 2).map { index in
            let radians = index * CGFloat.pi / 180
            
            return CGPoint(
                x: CGFloat(center.x + radius * cos(radians)),
                y: CGFloat(center.y + radius * sin(radians))
            )
        }
    }
    
    static func cycle(
        _ point: CGPoint,
        center: CGPoint
    ) -> Self {
        let vector = Vector(point, center)
        let topPoint = vector.point(distance: -70, other: point)
        let startToTopVector = Vector(point, topPoint)
        let finalPoint = startToTopVector.rotated(by: .pi * 0.4).point(distance: 5, other: point)
        return [
            point,
            startToTopVector.rotated(by: -.pi / 3).point(distance: 10, other: point),
            startToTopVector.rotated(by: -.pi / 4).point(distance: 40, other: point),
            topPoint,
            startToTopVector.rotated(by: .pi / 4).point(distance: 40, other: point),
            startToTopVector.rotated(by: .pi / 3).point(distance: 10, other: point),
        ]
//        + .arrow(
//            startPoint: finalPoint,
//            tipPoint: point,
//            arrowSpan: 30
//        )
    }
}

enum Geometry {
    struct Circle {
        let center: CGPoint
        let radius: CGFloat
    }
    
    static func intersections(
        pointA: CGPoint,
        pointB: CGPoint,
        circle: Geometry.Circle
    ) -> (CGPoint, CGPoint) {
        let vector = Vector(pointA, pointB)
        let a: CGFloat = pow(vector.x, 2) + pow(vector.y, 2)
        let b: CGFloat = 2 * vector.x * (pointA.x - circle.center.x) + 2 * vector.y * (pointA.y - circle.center.y)
        let c: CGFloat = pow(pointA.x - circle.center.x, 2) + pow(pointA.y - circle.center.y, 2) - pow(circle.radius, 2)
        let tOne: CGFloat = (-b + sqrt(pow(b, 2) - 4 * a * c)) / (2 * a)
        let tTwo: CGFloat = (-b - sqrt(pow(b, 2) - 4 * a * c)) / (2 * a)
        
        return (
            CGPoint(x: vector.x * tOne + pointA.x, y: vector.y * tOne + pointA.y),
            CGPoint(x: vector.x * tTwo + pointA.x, y: vector.y * tTwo + pointA.y)
        )
    }
}

/// Inspired from: https://github.com/nicklockwood/VectorMath/blob/master/VectorMath/VectorMath.swift
struct Vector: Hashable {
    var x: CGFloat
    var y: CGFloat
    
    typealias Scalar = CGFloat
    
    init(x: Scalar, y: Scalar) {
        self.x = x
        self.y = y
    }
    
    init(_ x: Scalar, _ y: Scalar) {
        self.init(x: x, y: y)
    }
    
    init(_ pointA: CGPoint, _ pointB: CGPoint) {
        self.init(pointB.x - pointA.x, pointB.y - pointA.y)
    }
    
    var lengthSquared: Scalar {
        return x * x + y * y
    }
    
    func point(distance: Scalar, other point: CGPoint) -> CGPoint {
        CGPoint(
            x: point.x + distance * normalized().x,
            y: point.y + distance * normalized().y
        )
    }
    
    func rotated(by radians: Scalar) -> Vector {
        let cs = cos(radians)
        let sn = sin(radians)
        return Vector(x * cs - y * sn, x * sn + y * cs)
    }
    
    func normalized() -> Vector {
        let lengthSquared = self.lengthSquared
        if lengthSquared ~= 0 || lengthSquared ~= 1 {
            return self
        }
        return self / sqrt(lengthSquared)
    }
    
    func angle(with v: Vector) -> Scalar {
        if self == v {
            return 0
        }

        let t1 = normalized()
        let t2 = v.normalized()
        let cross = t1.cross(t2)
        let dot = max(-1, min(1, t1.dot(t2)))

        return atan2(cross, dot)
    }
    
    func dot(_ v: Vector) -> Scalar {
        return x * v.x + y * v.y
    }

    func cross(_ v: Vector) -> Scalar {
        return x * v.y - y * v.x
    }
    
    static func / (lhs: Vector, rhs: Vector) -> Vector {
        return Vector(lhs.x / rhs.x, lhs.y / rhs.y)
    }
    
    static func / (lhs: Vector, rhs: Scalar) -> Vector {
        return Vector(lhs.x / rhs, lhs.y / rhs)
    }
    
    static prefix func - (v: Vector) -> Vector {
        return Vector(-v.x, -v.y)
    }
    
    static func + (lhs: Vector, rhs: Vector) -> Vector {
        return Vector(lhs.x + rhs.x, lhs.y + rhs.y)
    }
    
    static func - (lhs: Vector, rhs: Vector) -> Vector {
        return Vector(lhs.x - rhs.x, lhs.y - rhs.y)
    }
}

extension CGPoint: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
}
