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

private enum AutomataLibraryServiceKey: DependencyKey {
  static let liveValue = AutomataLibraryService.live
}

extension DependencyValues {
    var automataLibraryService: AutomataLibraryService {
    get { self[AutomataLibraryServiceKey.self] }
    set { self[AutomataLibraryServiceKey.self] = newValue }
  }
}

/// Service to interact with ALT frameworks
struct AutomataLibraryService {
    /// Simulates input for a given FA.
    /// Throws `AutomataLibraryError` if the input was rejected.
    let simulateInput: (
        _ input: [String],
        _ states: [AutomatonState],
        _ initialState: AutomatonState,
        _ finalStates: [AutomatonState],
        _ alphabet: [String],
        _ transitions: [AutomatonTransition]
    ) throws -> Void
}

extension AutomataLibraryService {
    static func successful() -> Self {
        Self(simulateInput: { _, _, _, _, _, _ in })
    }
}
