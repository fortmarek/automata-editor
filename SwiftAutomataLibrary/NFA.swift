public final class NFA {
    private let automaton: NFA_objc
    
    public init(
        states: [String],
        inputAlphabet: [String],
        initialState: String,
        finalStates: [String]
    ) {
        let transitions: [Transition_objc] = [
            Transition_objc(
                initialState,
                toState: finalStates[0],
                symbols: inputAlphabet
            ),
        ]
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
