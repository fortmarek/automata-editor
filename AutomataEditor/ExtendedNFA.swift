final class ExtendedNFA {
    private let automaton: ExtendedNFA_objc
    
    init(
        states: [String],
        initialState: String,
        finalStates: [String]
    ) {
        automaton = ExtendedNFA_objc(
            states,
            initialState: initialState,
            finalStates: finalStates
        )
    }
    
    public var initialState: String {
        automaton.getInitialState()
    }
    
    public var states: [String] {
        automaton.getStates() as! [String]
    }
}
