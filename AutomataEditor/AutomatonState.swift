import UIKit

struct AutomatonState: Equatable, Identifiable {
    var name: String = ""
    var isEndState: Bool = false
    var center: CGPoint
    let radius: CGFloat
    
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

    var id: CGPoint {
        center
    }
}
