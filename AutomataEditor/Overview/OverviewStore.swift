import Foundation
import ComposableArchitecture

struct AutomatonFile: Equatable {
    let url: URL
    let name: String
}

struct OverviewFeature: ReducerProtocol {
    struct State: Equatable {
        var isDocumentSheetPresented = false
        var isEditorPresented = false
        var editor: EditorState?
        var automatonFiles: [AutomatonFile] = []
    }
    enum Action: Equatable {
        case isDocumentSheetPresentedChanged(Bool)
        case isEditorPresentedChanged(Bool)
        case editor(EditorAction)
        case createNewAutomaton
        case selectedAutomaton(URL)
        case loadedAutomaton(URL, AutomatonDocument)
        case loadAutomata
        case loadedAutomata([URL])
    }
    
    @Dependency(\.automatonDocumentService) var automatonDocumentService
    
    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case let .isDocumentSheetPresentedChanged(isDocumentSheetPresented):
            state.isDocumentSheetPresented = isDocumentSheetPresented
            return .none
        case let .selectedAutomaton(url):
            return .task {
                let automatonDocument = try await automatonDocumentService.readAutomaton(url)
                return .loadedAutomaton(url, automatonDocument)
            }
        case let .loadedAutomaton(url, automaton):
            state.editor = EditorState(
                id: automaton.id,
                automatonStatesDict: automaton.automatonStates,
                transitionsDict: automaton.transitions
            )
            state.isEditorPresented = true
            return .none
        case let .isEditorPresentedChanged(isEditorPresented):
            state.isEditorPresented = isEditorPresented
            return .none
        case .editor:
            return .none
        case .createNewAutomaton:
            return .task {
                let url = try await automatonDocumentService.createNewAutomaton()
                return .selectedAutomaton(url)
            }
        case .loadAutomata:
            return .task {
                let urls = try await automatonDocumentService.loadAutomata()
                return .loadedAutomata(urls)
            }
        case let .loadedAutomata(urls):
            state.automatonFiles = urls.map { url in
                AutomatonFile(url: url, name: String(url.lastPathComponent.split(separator: ".").first ?? ""))
            }
            return .none
        }
    }
}
