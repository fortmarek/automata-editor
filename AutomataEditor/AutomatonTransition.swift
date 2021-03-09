import UIKit

struct AutomatonTransition: Equatable, Identifiable {
    let startState: AutomatonState.ID?
    let endState: AutomatonState.ID?
    var symbol: String = ""
    let scribblePosition: CGPoint
    let stroke: Stroke
    
    var id: Stroke {
        stroke
    }
}
