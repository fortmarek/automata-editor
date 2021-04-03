import SwiftUI
import ComposableArchitecture

private final class DocumentStore {
    var stores: [UUID: EditorStore] = [:]
}

@main
struct AutomataEditorApp: App {
    private var documentStore = DocumentStore()
    
    var body: some Scene {
        DocumentGroup(newDocument: EditorState()) { file -> EditorView in
            let store = documentStore.stores[file.document.id] ?? EditorStore(
                initialState: file.document,
                reducer: editorReducer,
                environment: EditorEnvironment(
                    automataClassifierService: .live(),
                    automataLibraryService: .live(),
                    shapeService: .live(),
                    idFactory: .live(),
                    mainQueue: DispatchQueue.main.eraseToAnyScheduler()
                )
            )
            documentStore.stores[file.document.id] = store
            
            return EditorView(
                set: {
                    file.document = $0
                },
                store: store
            )
        }
    }
}
