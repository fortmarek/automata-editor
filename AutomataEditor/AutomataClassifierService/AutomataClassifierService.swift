import Foundation
import Combine
import ComposableArchitecture

enum AutomatonShape: Equatable {
    case transition(Stroke)
    case state(Stroke)
}

enum AutomataClassifierError: Error, Equatable {
    case shapeNotRecognized
}

struct AutomataClassifierService {
    let recognizeStroke: (Stroke) -> Effect<AutomatonShape, AutomataClassifierError>
}

#if DEBUG
extension AutomataClassifierService {
    static let successfulTransition = Self(
        recognizeStroke: { stroke in
            Just(
                .transition(stroke)
            )
            .setFailureType(to: AutomataClassifierError.self)
            .eraseToEffect()
        }
    )
    static let successfulState = Self(
        recognizeStroke: { stroke in
            Just(
                .state(stroke)
            )
            .setFailureType(to: AutomataClassifierError.self)
            .eraseToEffect()
        }
    )
    
    static func successfulShape(_ shape: @escaping () -> AutomatonShapeType) -> Self {
        Self(
            recognizeStroke: { stroke in
                let automatonShape: AutomatonShape
                switch shape() {
                case .arrow:
                    automatonShape = .transition(stroke)
                case .circle:
                    automatonShape = .state(stroke)
                }
                
                return Just(
                    automatonShape
                )
                .setFailureType(to: AutomataClassifierError.self)
                .eraseToEffect()
            }
        )
    }
}
#endif
