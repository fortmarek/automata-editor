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

private enum AutomataClassifierServiceKey: DependencyKey {
  static let liveValue = AutomataClassifierService.live
}

extension DependencyValues {
  var automataClassifierService: AutomataClassifierService {
    get { self[AutomataClassifierServiceKey.self] }
    set { self[AutomataClassifierServiceKey.self] = newValue }
  }
}

/// Service to classify strokes as `AutomatonShape`.
struct AutomataClassifierService {
    /// Recognizes stroke and returns it as a case of `AutomatonShape`
    let recognizeStroke: (Stroke) async throws -> AutomatonShape
}

extension AutomataClassifierService {
    static let successfulTransition = Self(
        recognizeStroke: { stroke in
            .transition(stroke)
        }
    )
    static let successfulState = Self(
        recognizeStroke: { stroke in
            .state(stroke)
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
                
                return automatonShape
            }
        )
    }
}
