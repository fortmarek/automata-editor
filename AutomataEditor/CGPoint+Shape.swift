import CoreGraphics

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
    
    static func arrow(
        startPoint: CGPoint,
        tipPoint: CGPoint
    ) -> Self {
        [
            startPoint,
            tipPoint,
            CGPoint(x: tipPoint.x - 0.1, y: tipPoint.y + 0.1),
            CGPoint(x: tipPoint.x - 1, y: tipPoint.y + 1),
            CGPoint(x: tipPoint.x - 20, y: tipPoint.y + 30),
            CGPoint(x: tipPoint.x - 20, y: tipPoint.y + 30),
            tipPoint,
            CGPoint(x: tipPoint.x - 0.1, y: tipPoint.y - 0.1),
            CGPoint(x: tipPoint.x - 1, y: tipPoint.y - 1),
            CGPoint(x: tipPoint.x - 20, y: tipPoint.y - 30),
            CGPoint(x: tipPoint.x - 20, y: tipPoint.y - 30),
        ]
    }
}

