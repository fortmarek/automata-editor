import Foundation
import Combine
import ComposableArchitecture

/// Automaton shapes with their strokes as associated values.
enum AutomatonShape: Equatable {
    case transition(Stroke)
    case transitionCycle(Stroke)
    case state(Stroke)
}

enum AutomataClassifierError: Error, Equatable {
    case shapeNotRecognized
}

/// Service to classify strokes as `AutomatonShape`.
struct AutomataClassifierService {
    /// Recognizes stroke and returns it as a case of `AutomatonShape`
    let recognizeStroke: (Stroke) -> Effect<AutomatonShape, AutomataClassifierError>
}

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
                case .cycle:
                    automatonShape = .transitionCycle(stroke)
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
