import SwiftUI
import Vision
import PencilKit
import ComposableArchitecture

struct EditorView: View {
    @Environment(\.colorScheme) var colorScheme
    @State var counter = 0
//    let set: (EditorState) -> Void
    let store: StoreOf<EditorFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
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
                HStack(alignment: .center, spacing: 10) {
                    Button(
                        action: {
                            viewStore.send(.clear)
                        }
                    ) {
                        Text("Clear")
                            .padding(5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                    }
                    VStack {
                        Button(
                            action: {
                                viewStore.send(.simulateInput)
                            }
                        ) {
                            Text("Simulate")
                                .padding(5)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.blue, lineWidth: 2)
                                )
                        }
                        ZStack {
                            TextView(
                                text: viewStore.binding(
                                    get: \.input,
                                    send: { .inputChanged($0) }
                                )
                            )
                            Button(
                                action: {
                                    viewStore.send(.removeLastInputSymbol)
                                }
                            ) {
                                Image(systemName: "delete.left")
                            }
                            .position(x: 180, y: 15)
                        }
                        .border(colorScheme == .dark ? Color.white : Color.black)
                        .frame(width: 200, height: 30)
                    }
                    EditorButton(
                        isSelected: viewStore.state.isPenSelected,
                        image: Image(systemName: "pencil")
                    ) {
                        viewStore.send(.selectedPen)
                    }
                    EditorButton(
                        isSelected: viewStore.state.isEraserSelected,
                        image: Image(systemName: "pencil.slash")
                    ) {
                        viewStore.send(.selectedEraser)
                    }
                }
            }
//            .onChange(of: viewStore.state, perform: set)
        }
    }
}
