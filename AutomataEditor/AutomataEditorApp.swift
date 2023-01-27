import SwiftUI
import ComposableArchitecture
import Foundation

@main
struct AutomataEditorApp: App {    
    var body: some Scene {
        WindowGroup {
            OverviewView(
                store: Store(
                    initialState: OverviewFeature.State(),
                    reducer: OverviewFeature()
                )
            )
        }
        
//        DocumentGroup(newDocument: EditorState()) { file -> EditorView in
//            let store = documentStore.stores[file.document.id] ?? EditorStore(
//                initialState: file.document,
//                reducer: editorReducer,
//                environment: EditorEnvironment(
//                    automataClassifierService: .live(),
//                    automataLibraryService: .live(),
//                    shapeService: .live(),
//                    idFactory: .live(),
//                    mainQueue: DispatchQueue.main.eraseToAnyScheduler()
//                )
//            )
//            documentStore.stores[file.document.id] = store
//
//            return EditorView(
//                set: {
//                    file.document = $0
//                },
//                store: store
//            )
//        }
    }
}
