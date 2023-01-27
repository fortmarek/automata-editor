import Foundation

struct AutomatonDocument: Codable {
    let id: UUID
    let transitions: [AutomatonTransition.ID : AutomatonTransition]
    let automatonStates: [AutomatonState.ID : AutomatonState]
}
