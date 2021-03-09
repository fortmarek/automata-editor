import UIKit

struct AutomatonTransition: Equatable, Identifiable {
    let startState: AutomatonState.ID?
    let endState: AutomatonState.ID?
    /// Symbol currently being written
    var currentSymbol: String = ""
    var symbols: [String] = []
    let scribblePosition: CGPoint
    let stroke: Stroke
    
    var id: Stroke {
        stroke
    }
}
