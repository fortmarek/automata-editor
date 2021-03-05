final class ExtendedNFA {
    private let automaton: ExtendedNFA_objc
    
    init(
        states: [String],
        inputAlphabet: [String],
        initialState: String,
        finalStates: [String]
    ) {
        automaton = ExtendedNFA_objc(
            states,
            inputAlphabet: inputAlphabet,
            initialState: initialState,
            finalStates: finalStates
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
