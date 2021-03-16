import UIKit

struct AutomatonTransition: Equatable, Identifiable {
    var startState: AutomatonState.ID?
    var endState: AutomatonState.ID?
    /// Symbol currently being written
    var currentSymbol: String = ""
    var symbols: [String] = []
    let scribblePosition: CGPoint
    let stroke: Stroke
    
    var startPoint: CGPoint {
        stroke.controlPoints[0]
    }
    
    var tipPoint: CGPoint {
        stroke.controlPoints[1]
    }
    
    var id: Stroke {
        stroke
    }
}
