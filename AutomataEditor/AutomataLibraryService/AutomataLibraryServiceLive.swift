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
    static func live() -> AutomataLibraryService {
        .init { input, states, initialState, finalStates, alphabet, transitions in
            Future<[AutomatonState], AutomataLibraryError> { promise in
                switch NFA(
                    states: states.map(\.symbol),
                    inputAlphabet: alphabet,
                    initialState: initialState.symbol,
                    finalStates: finalStates.map(\.symbol),
                    transitions: transitions
                        .compactMap { transition -> Transition? in
                            guard
                                let startState = transition.startState,
                                let endState = transition.endState
                            else { return nil }
                            return Transition(
                                fromState: startState.symbol,
                                toState: endState.symbol,
                                symbols: [transition.symbol]
                            )
                        }
                )
                .simulate(input: input) {
                case let .succeeded(resultStates):
                    promise(
                        .success(
                            states.filter { resultStates.contains($0.symbol) }
                        )
                    )
                case let .failed(resultStates):
                    promise(
                        .failure(
                            .failed(
                                states.filter {
                                    resultStates.contains($0.symbol)
                                }
                            )
                        )
                    )
                }
            }
            .eraseToEffect()
        }
    }
}
