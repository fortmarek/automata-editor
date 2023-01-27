import UIKit

struct AutomatonState: Equatable, Identifiable, Codable {
    let id: String
    var name: String = ""
    var isFinalState: Bool = false
    var center: CGPoint
    let radius: CGFloat
    var dragPoint: CGPoint

    init(
        id: String,
        center: CGPoint,
        radius: CGFloat
    ) {
        self.id = id
        self.center = center
        self.radius = radius
        self.dragPoint = CGPoint(
            x: center.x,
            y: center.y - radius
        )
    }

    var currentDragPoint: CGPoint {
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
    
    var scribblePosition: CGPoint {
        center
    }
}
