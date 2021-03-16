import UIKit

struct AutomatonTransition: Equatable, Identifiable {
    enum TransitionType: Equatable, Hashable {
        case cycle(CGPoint, center: CGPoint)
        case normal(startPoint: CGPoint, tipPoint: CGPoint, flexPoint: CGPoint)
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
    
    var stroke: Stroke {
        switch type {
        case let .cycle(point, center: center):
            return Stroke(
                controlPoints: .cycle(point, center: center)
            )
        case let .normal(
            startPoint: startPoint,
            tipPoint: tipPoint,
            flexPoint: flexPoint
        ):
            return Stroke(
                controlPoints: .arrow(startPoint: startPoint, tipPoint: tipPoint, flexPoint: flexPoint)
            )
        }
    }
    
    var startPoint: CGPoint? {
        switch type {
        case .cycle:
            return nil
        case let .normal(
            startPoint: startPoint,
            tipPoint: _,
            flexPoint: _
        ):
            return startPoint
        }
    }
    
    var tipPoint: CGPoint? {
        switch type {
        case .cycle:
            return nil
        case let .normal(
            startPoint: _,
            tipPoint: tipPoint,
            flexPoint: _
        ):
            return tipPoint
        }
    }
    
    var flexPoint: CGPoint? {
        get {
            switch type {
            case .cycle:
                return nil
            case let .normal(
                startPoint: _,
                tipPoint: _,
                flexPoint: flexPoint
            ):
                return flexPoint
            }
        }
        set {
            guard let newValue = newValue else { return }
            switch type {
            case .cycle:
                break
            case let .normal(
                startPoint: startPoint,
                tipPoint: tipPoint,
                flexPoint: _
            ):
                type = .normal(
                    startPoint: startPoint,
                    tipPoint: tipPoint,
                    flexPoint: newValue
                )
            }
        }
    }
    
    var id: CGPoint {
        switch type {
        case let .cycle(point, center: _):
            return point
        case let .normal(
            startPoint: startPoint,
            tipPoint: _,
            flexPoint: _
        ):
            return startPoint
        }
    }
}
