final class ExtendedNFA {
    private let automaton: ExtendedNFA_objc
    
    init(
        initialState: String
    ) {
        automaton = ExtendedNFA_objc(
            initialState
        )
    }
    
    public var initialState: String {
        automaton.getInitialState()
    }
}
