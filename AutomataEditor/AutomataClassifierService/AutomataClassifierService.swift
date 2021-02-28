import Foundation
import Combine
import ComposableArchitecture

enum AutomataShape: Equatable {
    case transition(Stroke)
    case state(Stroke)
}

enum AutomataClassifierError: Error, Equatable {
    case shapeNotRecognized
}

struct AutomataClassifierService {
    let recognizeStroke: (Stroke) -> Effect<AutomataShape, AutomataClassifierError>
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
}
#endif
