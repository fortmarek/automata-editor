//
//  AutomataEditorApp.swift
//  AutomataEditor
//
//  Created by Marek Fořt on 17.02.2021.
//

import SwiftUI

@main
struct AutomataEditorApp: App {
    var body: some Scene {
        WindowGroup {
            EditorView(
                store: EditorStore(
                    initialState: .init(),
                    reducer: editorReducer,
                    environment: EditorEnvironment()
                )
            )
        }
    }
}
