import CoreGraphics
import PencilKit

struct Stroke: Equatable, Hashable {
    let controlPoints: [CGPoint]
    
    init(
        controlPoints: [CGPoint]
    ) {
        self.controlPoints = controlPoints
    }
    
    init(_ stroke: PKStroke) {
        controlPoints = stroke.path
            .interpolatedPoints(by: .distance(50))
            .map(\.location)
    }
    
    func pkStroke() -> PKStroke {
        PKStroke(
            ink: PKInk(.pen),
            path: PKStrokePath(
                controlPoints: controlPoints.map(strokePoint),
                creationDate: Date()
            )
        )
    }
    
    private func strokePoint(
        _ location: CGPoint
    ) -> PKStrokePoint {
        PKStrokePoint(
            location: location,
            timeOffset: 0,
            size: CGSize(width: 4, height: 4),
            opacity: 1,
            force: 1,
            azimuth: 0,
            altitude: 0
        )
    }
}
