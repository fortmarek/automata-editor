import UIKit

struct AutomatonState: Equatable, Identifiable {
    var name: String = ""
    let scribblePosition: CGPoint
    let stroke: Stroke
    /// Stroke for second circle around `stroke` to indicate this state is one of the end states
    var endStroke: Stroke?
    
    var id: Stroke {
        stroke
    }
}
