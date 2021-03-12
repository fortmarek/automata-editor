import UIKit

struct AutomatonTransition: Equatable, Identifiable {
    var startState: AutomatonState.ID?
    var endState: AutomatonState.ID?
    /// Symbol currently being written
    var currentSymbol: String = ""
    var symbols: [String] = []
    let scribblePosition: CGPoint
    let stroke: Stroke
    
    var id: Stroke {
        stroke
    }
}
