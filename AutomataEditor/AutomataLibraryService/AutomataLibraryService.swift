//
//  AutomataLibraryService.swift
//  AutomataEditor
//
//  Created by Marek Fořt on 05.03.2021.
//

import Foundation
import ComposableArchitecture
import Combine

enum AutomataLibraryError: Error, Equatable {
    case failed
}

struct AutomataLibraryService {
    let simulateInput: (
        _ input: [String],
        _ states: [AutomatonState],
        _ initialState: AutomatonState,
        _ finalStates: [AutomatonState],
        _ alphabet: [String],
        _ transitions: [AutomatonTransition]
    ) -> Effect<Void, AutomataLibraryError>
}

extension AutomataLibraryService {
    static func successful() -> Self {
        .init(
            simulateInput: { _, _, _, _, _, _ in
                Just(())
                    .setFailureType(to: AutomataLibraryError.self)
                    .eraseToEffect()
            }
        )
    }
}
