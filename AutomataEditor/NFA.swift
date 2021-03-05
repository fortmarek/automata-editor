final class NFA {
    private let automaton: NFA_objc
    
    init(
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
    
    public var initialState: String {
        print("Final: ", automaton.getFinalStates())
        print("Input alphabet: ", automaton.getInputAlphabet())
        return automaton.getInitialState()
    }
    
    public var states: [String] {
        automaton.getStates() as! [String]
    }
    
    func simulate(input: String) -> AutomatonRunResult {
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

enum AutomatonRunResult {
    case succeeded([String])
    case failed([String])
}
