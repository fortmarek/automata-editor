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
                            )
                        }
                )
                .simulate(input: input) {
                case let .succeeded(resultStates):
                    promise(
                        .success(
                            states.filter { resultStates.contains($0.name) }
                        )
                    )
                case let .failed(resultStates):
                    promise(
                        .failure(
                            .failed(
                                states.filter {
                                    resultStates.contains($0.name)
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
