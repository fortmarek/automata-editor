import SwiftUI
import Vision
import PencilKit
import ComposableArchitecture

struct EditorView: View {
//    let set: (EditorState) -> Void
    let store: StoreOf<EditorFeature>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                ZStack {
                    CanvasView(
                        shouldDeleteLastStroke: viewStore.binding(
                            get: \.shouldDeleteLastStroke,
                            send: EditorFeature.Action.shouldDeleteLastStrokeChanged
                        ),
                        strokes: viewStore.binding(
                            get: \.strokes,
                            send: EditorFeature.Action.strokesChanged
                        ),
                        tool: viewStore.state.tool
                    )
                    TransitionsView(
                        transitions: viewStore.transitions,
                        toggleEpsilonInclusion: { viewStore.send(.toggleEpsilonInclusion($0)) },
                        transitionSymbolRemoved: { viewStore.send(.transitionSymbolRemoved($0, $1)) },
                        transitionSymbolChanged: { viewStore.send(.transitionSymbolChanged($0, $1)) },
                        transitionSymbolAdded: { viewStore.send(.transitionSymbolAdded($0)) },
                        transitionDragged: {
                            viewStore.send(.transitionFlexPointChanged($0, $1))
                        },
                        transitionFinishedDragging: {
                            viewStore.send(.transitionFlexPointFinishedDragging($0, $1))
                        }
                    )
                    AutomatonStatesView(
                        automatonStates: viewStore.automatonStates,
                        stateSymbolChanged: { viewStore.send(.stateSymbolChanged($0, $1)) },
                        automatonStateDragged: { viewStore.send(.stateDragPointChanged($0, $1)) },
                        automatonStateFinishedDragging: { viewStore.send(.stateDragPointFinishedDragging($0, $1)) }
                    )
                    Text("Output: \(viewStore.outputString)")
                        .frame(width: 140)
                        .position(x: 70, y: 50)
                }
                HStack {
                    TextField(
                        "Automaton input",
                        text: viewStore.binding(
                            get: \.input,
                            send: { .inputChanged($0) }
                        )
                    )
                    .foregroundColor(.black)
                    Button(
                        action: {
                            viewStore.send(.removeLastInputSymbol)
                        }
                    ) {
                        Image(systemName: "delete.left")
                            .foregroundColor(Color(UIColor.opaqueSeparator))
                    }
                }
                .frame(width: 200)
                .padding(15)
                .background(.white)
                .cornerRadius(15)
            }
            .toolbar {
                ToolbarItemGroup(placement: .principal) {
                    HStack {
                        Button(action: { viewStore.send(.simulateInput) }) {
                            Image(systemName: "play.fill")
                        }
                        Button(action: { viewStore.send(.selectedPen) }) {
                            Image(systemName: viewStore.state.isPenSelected ? "pencil.circle.fill" : "pencil.circle")
                        }
                        Button(action: { viewStore.send(.selectedEraser) }) {
                            Image(systemName: viewStore.state.isEraserSelected ? "eraser.fill" : "eraser")
                        }
                    }
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    Button(action: { viewStore.send(.clear) }) {
                        Image(systemName: "trash.fill")
                    }
                }
            }
            .onChange(of: viewStore.state, perform: { viewStore.send(.stateUpdated($0)) })
        }
    }
}
