//
//  AutomataLibraryService.swift
//  AutomataEditor
//
//  Created by Marek Fořt on 05.03.2021.
//

import Foundation
import ComposableArchitecture

enum AutomataLibraryError: Error, Equatable {
    case failed([AutomatonState])
}

struct AutomataLibraryService {
    let simulateInput: (
        _ input: String,
        _ states: [AutomatonState],
        _ initialState: AutomatonState,
        _ finalStates: [AutomatonState],
        _ alphabet: [String],
        _ transitions: [AutomatonTransition]
    ) -> Effect<[AutomatonState], AutomataLibraryError>
}
