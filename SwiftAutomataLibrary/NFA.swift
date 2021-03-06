public struct NFA {
    private let automaton: NFA_objc
    
    public init(
        states: [String],
        inputAlphabet: [String],
        initialState: String,
        finalStates: [String],
        transitions: [Transition]
    ) {
        let transitions: [Transition_objc] = transitions
            .map {
                Transition_objc(
                    $0.fromState,
                    toState: $0.toState,
                    symbols: $0.symbols,
                    isEpsilonIncluded: $0.isEpsilonIncluded
                )
            }
        automaton = NFA_objc(
            states,
            inputAlphabet: inputAlphabet,
            initialState: initialState,
            finalStates: finalStates,
            transitions: transitions
        )
    }
    
    public func simulate(input: [String]) -> Bool {
        automaton.simulate(
            input
        )
    }
}

public enum AutomatonRunResult {
    case succeeded([String])
    case failed([String])
}
