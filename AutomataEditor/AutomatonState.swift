import UIKit

struct AutomatonState: Equatable, Identifiable {
    var name: String = ""
    var isEndState: Bool = false
    var center: CGPoint
    let radius: CGFloat
    var currentDragPoint: CGPoint
    let id = UUID()

    init(
        center: CGPoint,
        radius: CGFloat
    ) {
        self.center = center
        self.radius = radius
        self.currentDragPoint = CGPoint(
            x: center.x,
            y: center.y - radius
        )
    }

    var dragPoint: CGPoint {
        get {
            CGPoint(
                x: center.x,
                y: center.y - radius
            )
        }
        set {
            center.x = newValue.x
            center.y = newValue.y + radius
        }
    }
    
    var stroke: Stroke {
        Stroke(
            controlPoints: .circle(
                center: center,
                radius: radius
            )
        )
    }
    
    var endStroke: Stroke? {
        guard isEndState else { return nil }
        return Stroke(
            controlPoints: .circle(
                center: center,
                radius: radius * 0.7
            )
        )
    }
    
    var scribblePosition: CGPoint {
        center
    }
}
