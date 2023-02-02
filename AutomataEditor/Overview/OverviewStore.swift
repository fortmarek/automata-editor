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
        var editor: EditorFeature.State?
        var automatonFiles: [AutomatonFile] = []
        var selectedAutomatonURL: URL?
        var isAlertForNewAutomatonNamePresented = false
        var automatonName = ""
    }
    enum Action: Equatable {
        case isDocumentSheetPresentedChanged(Bool)
        case isEditorPresentedChanged(Bool)
        case editor(EditorFeature.Action)
        case createNewAutomaton
        case selectedAutomaton(URL)
        case loadedAutomaton(URL, AutomatonDocument)
        case loadAutomata
        case loadedAutomata([URL])
        case automatonSaved
        case automatonNameChanged(String)
        case isAlertForNewAutomatonNamePresentedChanged(Bool)
    }
    
    @Dependency(\.automatonDocumentService) var automatonDocumentService
    
    var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case let .isDocumentSheetPresentedChanged(isDocumentSheetPresented):
                state.isDocumentSheetPresented = isDocumentSheetPresented
                return .none
            case let .selectedAutomaton(url):
                state.automatonName = ""
                return .task {
                    let automatonDocument = try await automatonDocumentService.readAutomaton(url)
                    return .loadedAutomaton(url, automatonDocument)
                }
            case let .loadedAutomaton(url, automaton):
                state.editor = EditorFeature.State(
                    automatonURL: url,
                    id: automaton.id,
                    automatonStatesDict: automaton.automatonStates,
                    transitionsDict: automaton.transitions
                )
                state.isEditorPresented = true
                return .none
            case let .isEditorPresentedChanged(isEditorPresented):
                state.isEditorPresented = isEditorPresented
                return .none
            case let .editor(action):
                switch action {
                case let .stateUpdated(editorState):
                    return .task {
                        try automatonDocumentService.saveAutomaton(
                            editorState.automatonURL,
                            AutomatonDocument(
                                id: editorState.id,
                                transitions: editorState.transitionsDict,
                                automatonStates: editorState.automatonStatesDict
                            )
                        )
                        
                        return .automatonSaved
                    }
                default:
                    return .none
                }
            case .automatonSaved:
                return .none
            case let .isAlertForNewAutomatonNamePresentedChanged(value):
                state.isAlertForNewAutomatonNamePresented = value
                return .none
            case .createNewAutomaton:
                let automatonName = state.automatonName
                return .task {
                    let url = try await automatonDocumentService.createNewAutomaton(automatonName)
                    return .selectedAutomaton(url)
                }
            case let .automatonNameChanged(name):
                state.automatonName = name
                return .none
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
        .ifLet(\.editor, action: /Action.editor) {
            EditorFeature()
        }
    }
}
