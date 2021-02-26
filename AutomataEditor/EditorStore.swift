import ComposableArchitecture

typealias EditorStore = Store<EditorState, EditorAction>
typealias EditorViewStore = ViewStore<EditorState, EditorAction>

struct EditorEnvironment {}

struct EditorState: Equatable {
    
}

enum EditorAction: Equatable {
    
}

let editorReducer = Reducer<EditorState, EditorAction, EditorEnvironment> { state, action, env in
    switch action {
    }
}
