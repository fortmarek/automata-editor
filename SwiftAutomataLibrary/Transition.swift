public struct Transition {
    public let fromState: String
    public let toState: String
    public let symbols: [String]
    public let isEpsilonIncluded: Bool
    
    public init(
        fromState: String,
        toState: String,
        symbols: [String],
        isEpsilonIncluded: Bool
    ) {
        self.fromState = fromState
        self.toState = toState
        self.symbols = symbols
        self.isEpsilonIncluded = isEpsilonIncluded
    }
}
