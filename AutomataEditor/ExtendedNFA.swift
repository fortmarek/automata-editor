final class ExtendedNFA {
    private let automaton: ExtendedNFA_objc
    
    init(
        states: [String],
        initialState: String
    ) {
        automaton = ExtendedNFA_objc(
            states,
            initialState: initialState
        )
    }
    
    public var initialState: String {
        automaton.getInitialState()
    }
    
    public var states: [String] {
        automaton.getStates() as! [String]
    }
}
