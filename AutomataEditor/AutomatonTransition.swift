import UIKit

struct AutomatonTransition: Equatable, Identifiable, Codable {
    enum TransitionType: Equatable, Hashable, Codable {
        case cycle(CGPoint, center: CGPoint, radians: CGFloat)
        case regular(startPoint: CGPoint, tipPoint: CGPoint, flexPoint: CGPoint)
        
        enum CodingKeys: String, CodingKey {
            case point
            case center
            case radians
            case startPoint
            case tipPoint
            case flexPoint
            case type
        }
        
        private enum CaseType: String, Codable {
            case cycle
            case regular
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(CaseType.self, forKey: .type)
            switch type {
            case .cycle:
                let point = try container.decode(CGPoint.self, forKey: .point)
                let center = try container.decode(CGPoint.self, forKey: .center)
                let radians = try container.decode(CGFloat.self, forKey: .radians)
                self = .cycle(point, center: center, radians: radians)
            case .regular:
                let startPoint = try container.decode(CGPoint.self, forKey: .startPoint)
                let tipPoint = try container.decode(CGPoint.self, forKey: .tipPoint)
                let flexPoint = try container.decode(CGPoint.self, forKey: .flexPoint)
                self = .regular(startPoint: startPoint, tipPoint: tipPoint, flexPoint: flexPoint)
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case let .cycle(point, center: center, radians: radians):
                try container.encode(CaseType.cycle, forKey: .type)
                try container.encode(point, forKey: .point)
                try container.encode(center, forKey: .center)
                try container.encode(radians, forKey: .radians)
            case let .regular(startPoint: startPoint, tipPoint: tipPoint, flexPoint: flexPoint):
                try container.encode(CaseType.regular, forKey: .type)
                try container.encode(startPoint, forKey: .startPoint)
                try container.encode(tipPoint, forKey: .tipPoint)
                try container.encode(flexPoint, forKey: .flexPoint)
            }
        }
    }
    
    let id: String
    var startState: AutomatonState.ID?
    var endState: AutomatonState.ID?
    /// Symbol currently being written
    var currentSymbol: String = ""
    var symbols: [String] = []
    var includesEpsilon: Bool = false
    var type: TransitionType
    /// Current flex point
    /// Needed for gesture
    /// Might not always correspond to the value if a gesture is currently underway
    var currentFlexPoint: CGPoint? = nil

    var scribblePosition: CGPoint? {
        /// Do not show editor for initial transition
        if endState != nil, startState == nil { return nil }
        switch type {
        case let .cycle(point, center: center, radians: _):
            let vector = Vector(center, point)
            return vector.rotated(by: .pi / 11).point(distance: 80, other: point)
        case let .regular(startPoint: _, tipPoint: _, flexPoint: flexPoint):
            return CGPoint(x: flexPoint.x, y: flexPoint.y - 50)
        }
    }
    
    var isInitialTransition: Bool {
        startState == nil && endState != nil
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
