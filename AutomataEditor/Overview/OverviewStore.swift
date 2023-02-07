import Foundation
import ComposableArchitecture

struct AutomatonFile: Equatable, Identifiable {
    let url: URL
    let name: String
    
    var id: URL {
        url
    }
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
        var isSelectingFiles = false
        var selectedAutomatonFileIDs: [AutomatonFile.ID] = []
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
        case selectFiles
        case doneSelectingFiles
        case removeSelectedFiles
        case removedSelectedFiles
    }
    
    @Dependency(\.automatonDocumentService) var automatonDocumentService
    
    var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .selectFiles:
                state.isSelectingFiles = true
                return .none
            case .doneSelectingFiles:
                state.isSelectingFiles = false
                state.selectedAutomatonFileIDs = []
                return .none
            case let .isDocumentSheetPresentedChanged(isDocumentSheetPresented):
                state.isDocumentSheetPresented = isDocumentSheetPresented
                return .none
            case let .selectedAutomaton(url):
                if state.isSelectingFiles {
                    if state.selectedAutomatonFileIDs.contains(url) {
                        state.selectedAutomatonFileIDs.removeAll(where: { $0 == url })
                    } else {
                        state.selectedAutomatonFileIDs.append(url)
                    }
                    
                    return .none
                }
                state.automatonName = ""
                return .task {
                    let automatonDocument = try await automatonDocumentService.readAutomaton(url)
                    return .loadedAutomaton(url, automatonDocument)
                }
            case .removeSelectedFiles:
                let selectedFileURLs = state.selectedAutomatonFileIDs
                return .task {
                    try automatonDocumentService.deleteAutomata(selectedFileURLs)
                    return .removedSelectedFiles
                }
                
            case .removedSelectedFiles:
                state.isSelectingFiles = false
                state.automatonFiles.removeAll(where: { state.selectedAutomatonFileIDs.contains($0.id) })
                state.selectedAutomatonFileIDs = []
                return .none
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
