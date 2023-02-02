import XCTest
import ComposableArchitecture
@testable import AutomataEditor

@MainActor
final class OverviewTests: XCTestCase {
    let automatonURL = URL(string: "file://some-file")!
    
    func testAutomatonIsSavedWhenEditorStateIsUpdated() async throws {
        let store = TestStore(
            initialState: OverviewFeature.State(),
            reducer: OverviewFeature()
        )
        let stubID = try XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
        store.dependencies.automatonDocumentService = .mock
        store.dependencies.idFactory = .mock { stubID.uuidString }
        
        let state = EditorFeature.State(
            automatonURL: automatonURL,
            id: stubID,
            automatonStatesDict: ["A": AutomatonState(id: "A", center: .zero, radius: .zero)]
        )
        await store.send(.loadedAutomaton(automatonURL, AutomatonDocument(id: stubID))) { [self] in
            $0.editor = EditorFeature.State(automatonURL: self.automatonURL, id: stubID)
            $0.isEditorPresented = true
        }
        await store.send(
            .editor(
                .stateUpdated(
                    state
                )
            )
        )
        await store.receive(.automatonSaved)
    }
}
