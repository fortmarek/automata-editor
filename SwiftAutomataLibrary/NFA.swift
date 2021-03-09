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
                    symbols: $0.symbols
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
    
    public func simulate(input: String) -> AutomatonRunResult {
        guard
            let result = automaton.simulate(input),
            let endStates = result.endStates as? [String]
        else { return .failed([]) }
        if result.succeeded {
            return .succeeded(endStates)
        } else {
            return .failed(endStates)
        }
    }
}

public enum AutomatonRunResult {
    case succeeded([String])
    case failed([String])
}
