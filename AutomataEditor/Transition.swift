import UIKit

struct Transition: Equatable, Identifiable {
    let startState: AutomatonState?
    let endState: AutomatonState?
    var symbol: String = ""
    let scribblePosition: CGPoint
    let stroke: Stroke
    
    var id: Stroke {
        stroke
    }
}
