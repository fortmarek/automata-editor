import Foundation
import ComposableArchitecture

struct OverviewFeature: ReducerProtocol {
    struct State: Equatable {
        var isDocumentSheetPresented = false
        var isEditorPresented = false
        var editor = EditorState()
    }
    enum Action: Equatable {
        case selectedDocument(URL)
        case isDocumentSheetPresentedChanged(Bool)
        case isEditorPresentedChanged(Bool)
        case editor(EditorAction)
    }
    
    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case let .isDocumentSheetPresentedChanged(isDocumentSheetPresented):
            state.isDocumentSheetPresented = isDocumentSheetPresented
            return .none
        case let .isEditorPresentedChanged(isEditorPresented):
            state.isEditorPresented = isEditorPresented
            print(state.isEditorPresented)
            return .none
        case .selectedDocument:
            return .none
        case .editor:
            return .none
        }
    }
}
