public struct Transition {
    public let fromState: String
    public let toState: String
    public let symbols: [String]
    
    public init(
        fromState: String,
        toState: String,
        symbols: [String]
    ) {
        self.fromState = fromState
        self.toState = toState
        self.symbols = symbols
    }
}
