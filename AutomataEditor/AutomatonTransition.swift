import UIKit

struct AutomatonTransition: Equatable, Identifiable {
    enum TransitionType: Equatable, Hashable {
        case cycle(CGPoint, center: CGPoint, radians: CGFloat)
        case regular(startPoint: CGPoint, tipPoint: CGPoint, flexPoint: CGPoint)
    }
    
    let id: String
    var startState: AutomatonState.ID?
    var endState: AutomatonState.ID?
    /// Symbol currently being written
    var currentSymbol: String = ""
    var symbols: [String] = []
    var includesEpsilon: Bool = false
    var scribblePosition: CGPoint? {
        /// Do not show editor for initial transition
        if endState != nil, startState == nil { return nil }
        switch type {
        case .cycle:
            let highestPoint = stroke.controlPoints.min(by: { $0.y < $1.y }) ?? .zero
            return CGPoint(
                x: highestPoint.x + 20,
                y: highestPoint.y - 20
            )
        case let .regular(startPoint: _, tipPoint: _, flexPoint: flexPoint):
            return CGPoint(x: flexPoint.x, y: flexPoint.y - 50)
        }
    }
    var type: TransitionType
    /// Current flex point
    /// Needed for gesture
    /// Might not always correspond to the value if a gesture is currently underway
    var currentFlexPoint: CGPoint? = nil
    
    var stroke: Stroke {
        switch type {
        case let .cycle(point, center: center, radians: _):
            return Stroke(
                controlPoints: .cycle(point, center: center)
            )
        case let .regular(
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
        get {
            switch type {
            case .cycle:
                return nil
            case let .regular(
                startPoint: startPoint,
                tipPoint: _,
                flexPoint: _
            ):
                return startPoint
            }
        }
        set {
            guard let newValue = newValue else { return }
            switch type {
            case .cycle:
                break
            case let .regular(
                startPoint: _,
                tipPoint: tipPoint,
                flexPoint: flexPoint
            ):
                type = .regular(
                    startPoint: newValue,
                    tipPoint: tipPoint,
                    flexPoint: flexPoint
                )
            }
        }
    }
    
    var tipPoint: CGPoint? {
        get {
            switch type {
            case .cycle:
                return nil
            case let .regular(
                startPoint: _,
                tipPoint: tipPoint,
                flexPoint: _
            ):
                return tipPoint
            }
        }
        set {
            guard let newValue = newValue else { return }
            switch type {
            case .cycle:
                break
            case let .regular(
                startPoint: startPoint,
                tipPoint: _,
                flexPoint: flexPoint
            ):
                type = .regular(
                    startPoint: startPoint,
                    tipPoint: newValue,
                    flexPoint: flexPoint
                )
            }
        }
    }
    
    var flexPoint: CGPoint? {
        get {
            switch type {
            case .cycle:
                return nil
            case let .regular(
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
            case let .regular(
                startPoint: startPoint,
                tipPoint: tipPoint,
                flexPoint: _
            ):
                type = .regular(
                    startPoint: startPoint,
                    tipPoint: tipPoint,
                    flexPoint: newValue
                )
            }
        }
    }
}
