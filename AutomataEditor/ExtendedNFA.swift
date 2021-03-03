public final class ExtendedNFA {
    private let automaton = ExtendedNFA_objc()
    
    public var initialState: String {
        automaton!.getInitialState()
    }
    
    public init() {}
}
