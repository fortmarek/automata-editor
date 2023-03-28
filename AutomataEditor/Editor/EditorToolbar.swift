import SwiftUI
import ComposableArchitecture

struct EditorToolbar: ToolbarContent {
    let viewStore: ViewStoreOf<EditorFeature>

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .principal) {
            HStack {
                Button(action: { withAnimation(.spring()) { _ = viewStore.send(.simulateInput) } }) {
                    Image(systemName: "play.fill")
                }
                Button(action: { viewStore.send(.selectedPen) }) {
                    Image(systemName: viewStore.state.isPenSelected ? "pencil.circle.fill" : "pencil.circle")
                }
                Button(action: { viewStore.send(.selectedEraser) }) {
                    Image(systemName: viewStore.state.isEraserSelected ? "eraser.fill" : "eraser")
                }
                Menu {
                    Button(action: { viewStore.send(.addNewState) }) {
                        Label("State", systemImage: "circle")
                    }
                    
                    Button(action: { viewStore.send(.startAddingTransition) }) {
                        Label("Transition", systemImage: "arrow.right")
                    }
                    Button(action: { viewStore.send(.startAddingCycle) }) {
                        Label("Cycle", systemImage: "arrow.counterclockwise")
                    }
                    Button(action: { viewStore.send(.startAddingFinalState) }) {
                        Label("Final state", systemImage: "circle.circle")
                    }
                    Button(action: { viewStore.send(.startAddingInitialState) }) {
                        Label("Initial state", systemImage: "arrow.right.to.line")
                    }
                } label: {
                    Label("Add new element", systemImage: "plus.circle")
                }
            }
        }
        ToolbarItemGroup(placement: .primaryAction) {
            switch viewStore.mode {
            case .editing, .erasing:
                Button(action: { viewStore.send(.clearButtonPressed) }) {
                    Image(systemName: "trash")
                }
            case .addingTransition:
                Button("Cancel", action: { viewStore.send(.stopAddingTransition) })
            case .addingCycle:
                Button("Cancel", action: { viewStore.send(.stopAddingCycle) })
            case .addingFinalState:
                Button("Cancel", action: { viewStore.send(.stopAddingFinalState) })
            case .addingInitialState:
                Button("Cancel", action: { viewStore.send(.stopAddingInitialState) })
            }
        }
    }
}
