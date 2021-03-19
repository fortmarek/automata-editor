import SwiftUI
import Vision
import PencilKit
import ComposableArchitecture

struct EditorView: View {
    @Environment(\.colorScheme) var colorScheme
    @State var counter = 0
    
    let store: EditorStore
    
    var body: some View {
        WithViewStore(store) { (viewStore: EditorViewStore) in
            VStack {
                ZStack {
                    CanvasView(
                        shouldDeleteLastStroke: viewStore.binding(
                            get: \.shouldDeleteLastStroke,
                            send: EditorAction.shouldDeleteLastStrokeChanged
                        ),
                        strokes: viewStore.binding(
                            get: \.strokes,
                            send: EditorAction.strokesChanged
                        ),
                        tool: viewStore.state.tool
                    )
                    TransitionsView(
                        transitions: viewStore.transitions,
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
                    VStack(alignment: .center) {
                        Text("Alphabet")
                        HStack {
                            TextView(
                                text: viewStore.binding(
                                    get: \.currentAlphabetSymbol,
                                    send: { .currentAlphabetSymbolChanged($0) }
                                )
                            )
                            .border(colorScheme == .dark ? Color.white : Color.black)
                            .frame(width: 100, height: 30)
                            Button(
                                action: { viewStore.send(.addedCurrentAlphabetSymbol) }
                            ) {
                                Image(systemName: "plus.circle.fill")
                            }
                        }
                        ForEach(viewStore.state.alphabetSymbols, id: \.self) { symbol in
                            HStack {
                                Text(symbol)
                                Button(
                                    action: { viewStore.send(.removedAlphabetSymbol(symbol)) }
                                ) {
                                    Image(systemName: "trash.fill")
                                }
                            }
                        }
                        Text("Output: \(viewStore.state.outputString)")
                            .frame(width: 150)
                    }
                    .position(x: 70, y: 100)
                }
                HStack(alignment: .top) {
                    VStack {
                        Button("Simulate") {
                            viewStore.send(.simulateInput(viewStore.state.input))
                        }
                        TextView(
                            text: viewStore.binding(
                                get: \.input,
                                send: { .inputChanged($0) }
                            )
                        )
                        .border(colorScheme == .dark ? Color.white : Color.black)
                        .frame(width: 200, height: 30)
                    }
                    Button("Clear") {
                        viewStore.send(.clear)
                    }
                    Button(
                        action: {
                            viewStore.send(.selectedPen)
                        }
                    ) {
                        viewStore.state.penImage
                            .resizable()
                            .frame(width: 20, height: 20)
                    }
                    Button(
                        action: {
                            viewStore.send(.selectedEraser)
                        }
                    ) {
                        viewStore.state.eraserImage
                            .resizable()
                            .frame(width: 20, height: 20)
                    }
                }
            }
        }
    }
    
    private func strokePoint(
        _ location: CGPoint
    ) -> PKStrokePoint {
        PKStrokePoint(
            location: location,
            timeOffset: 0,
            size: CGSize(width: 4, height: 4),
            opacity: 1,
            force: 1,
            azimuth: 0,
            altitude: 0
        )
    }
}

extension CGPoint: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
}

//struct EditorView_Previews: PreviewProvider {
//    static var previews: some View {
//        EditorView(
//            store: EditorStore(
//                initialState: .init(
//                    outputString: "✅ with states A, B, C",
//                    alphabetSymbols: [
//                        "A",
//                        "B",
//                    ],
//                    transitions: [
//                        AutomatonTransition(
//                            startState: nil,
//                            endState: nil,
//                            currentSymbol: "A",
//                            symbols: ["B", "C"],
//                            scribblePosition: CGPoint(x: 400, y: 200),
//                            stroke: Stroke(
//                                controlPoints: .arrow(
//                                    startPoint: CGPoint(x: 380, y: 200),
//                                    tipPoint: CGPoint(x: 420, y: 200)
//                                )
//                            )
//                        )
//                    ]
//                ),
//                reducer: editorReducer,
//                environment: EditorEnvironment(
//                    automataClassifierService: .successfulTransition,
//                    automataLibraryService: .successful(),
//                    mainQueue: DispatchQueue.main.eraseToAnyScheduler()
//                )
//            )
//        )
//    }
//}

