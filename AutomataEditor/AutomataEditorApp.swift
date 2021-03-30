import SwiftUI
import ComposableArchitecture

@main
struct AutomataEditorApp: App {
    var body: some Scene {
        WindowGroup {
            EditorView(
                store: EditorStore(
                    initialState: .init(),
                    reducer: editorReducer,
                    environment: EditorEnvironment(
                        automataClassifierService: .live(),
                        automataLibraryService: .live(),
                        shapeService: .live(),
                        idFactory: .live(),
                        mainQueue: DispatchQueue.main.eraseToAnyScheduler()
                    )
                )
            )
        }
    }
}
