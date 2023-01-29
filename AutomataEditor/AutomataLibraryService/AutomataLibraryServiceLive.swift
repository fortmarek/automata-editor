//
//  AutomataLibraryServiceLive.swift
//  AutomataEditor
//
//  Created by Marek Fořt on 05.03.2021.
//

import Foundation
import ComposableArchitecture
import SwiftAutomataLibrary
import Combine

extension AutomataLibraryService {
    static let live = Self { input, states, initialState, finalStates, alphabet, transitions in
        let accepted = NFA(
            states: states.map(\.name),
            inputAlphabet: alphabet,
            initialState: initialState.name,
            finalStates: finalStates.map(\.name),
            transitions: transitions
                .compactMap { transition -> Transition? in
                    guard
                        let startState = states.first(where: { $0.id == transition.startState }),
                        let endState = states.first(where: { $0.id == transition.endState })
                    else { return nil }
                    return Transition(
                        fromState: startState.name,
                        toState: endState.name,
                        symbols: transition.symbols
                            + (transition.currentSymbol.isEmpty ? [] : [transition.currentSymbol]),
                        isEpsilonIncluded: transition.includesEpsilon
                    )
                }
        )
        .simulate(input: input)

        if accepted {
            // noop
        } else {
            throw AutomataLibraryError.failed
        }
    }
}
