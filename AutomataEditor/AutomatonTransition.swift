import UIKit

struct AutomatonTransition: Equatable, Identifiable {
    enum TransitionType: Equatable {
        case cycle
        /// Associated value is flex point for changing shape of the transition
        case normal(CGPoint)
    }
    
    var startState: AutomatonState.ID?
    var endState: AutomatonState.ID?
    /// Symbol currently being written
    var currentSymbol: String = ""
    var symbols: [String] = []
    var scribblePosition: CGPoint
    var type: TransitionType
    /// Current flex point
    /// Needed for gesture
    /// Might not always correspond to the value if a gesture is currently underway
    var currentFlexPoint: CGPoint? = nil
    let controlPoints: [CGPoint]
    
    var stroke: Stroke {
        switch type {
        case .cycle:
            return Stroke(
                controlPoints: [startPoint, tipPoint]
            )
        case let .normal(flexPoint):
            return Stroke(
                controlPoints: [
                    startPoint,
                    flexPoint,
                    flexPoint,
                    tipPoint,
                ]
            )
        }
    }

    var flexPoint: CGPoint? {
        get {
            switch type {
            case .cycle:
                return nil
            case let .normal(flexPoint):
                return flexPoint
            }
        }
        set {
            guard let newValue = newValue else { return }
            switch type {
            case .cycle:
                break
            case .normal:
                type = .normal(newValue)
            }
        }
    }
    
    var startPoint: CGPoint {
        controlPoints[0]
    }
    
    var tipPoint: CGPoint {
        controlPoints[1]
    }
    
    var id: [CGPoint] {
        controlPoints
    }
}
