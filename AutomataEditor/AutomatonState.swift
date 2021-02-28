import UIKit

struct AutomatonState: Equatable, Identifiable {
    var symbol: String = ""
    let scribblePosition: CGPoint
    let stroke: Stroke
    
    var id: Stroke {
        stroke
    }
}
