import Foundation
    
struct AutomatonDocument: Equatable, Codable {
    let id: UUID
    let transitions: [AutomatonTransition.ID : AutomatonTransition]
    let automatonStates: [AutomatonState.ID : AutomatonState]
    
    init(
        id: UUID = UUID(),
        transitions: [AutomatonTransition.ID : AutomatonTransition] = [:],
        automatonStates: [AutomatonState.ID : AutomatonState] = [:]
    ) {
        self.id = id
        self.transitions = transitions
        self.automatonStates = automatonStates
    }
}
