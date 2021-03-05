final class ExtendedNFA {
    private let automaton: ExtendedNFA_objc
    
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
        automaton = ExtendedNFA_objc(
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
}
