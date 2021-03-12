import SwiftUI
import Vision
import PencilKit
import ComposableArchitecture

struct EditorView: View {
    @State var canvasView: PKCanvasView = .init()
    @Environment(\.colorScheme) var colorScheme
    
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
                        canvasView: $canvasView,
                        strokes: viewStore.binding(
                            get: \.strokes,
                            send: EditorAction.strokesChanged
                        )
                    )
                    ForEach(viewStore.automatonStates) { automatonState in
                        TextEditor(
                            text: viewStore.binding(
                                get: { $0.automatonStates.first(where: { $0.id == automatonState.id })?.name ?? "" },
                                send: { .stateSymbolChanged(automatonState, $0) }
                            )
                        )
                        .border(colorScheme == .dark ? Color.white : Color.black, width: 2)
                        .frame(width: 100, height: 30)
                        .position(automatonState.scribblePosition)
                    }
                    ForEach(viewStore.transitions) { transition in
                        VStack(alignment: .center) {
                            FlexibleView(
                                data: transition.symbols,
                                spacing: 3,
                                alignment: .leading,
                                content: { symbol in
                                    Button(
                                        action: { viewStore.send(.transitionSymbolRemoved(transition, symbol)) }
                                    ) {
                                        HStack {
                                            Text(symbol)
                                                .foregroundColor(Color.black)
                                            Image(systemName: "xmark")
                                                .foregroundColor(Color.black)
                                        }
                                        .padding(.all, 5)
                                        .background(Color.white)
                                        .cornerRadius(10)
                                    }
                                }
                            )
                            .frame(width: 200)
                            HStack {
                                TextEditor(
                                    text: viewStore.binding(
                                        get: { _ in transition.currentSymbol },
                                        send: { .transitionSymbolChanged(transition, $0) }
                                    )
                                )
                                .border(colorScheme == .dark ? Color.white : Color.black, width: 2)
                                .frame(width: 100, height: 30)
                                Button(
                                    action: { viewStore.send(.transitionSymbolAdded(transition)) }
                                ) {
                                    Image(systemName: "plus.circle.fill")
                                }
                            }
                        }
                        .position(transition.scribblePosition)
                    }
                    VStack(alignment: .center) {
                        Text("Alphabet")
                        HStack {
                            TextEditor(
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
                    }
                    .position(x: 70, y: 100)
                }
                HStack(alignment: .top) {
                    VStack {
                        Button("Simulate") {
                            viewStore.send(.simulateInput(viewStore.state.input))
                        }
                        TextEditor(
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

struct EditorView_Previews: PreviewProvider {
    static var previews: some View {
        EditorView(
            store: EditorStore(
                initialState: .init(
                    alphabetSymbols: [
                        "A",
                        "B",
                    ],
                    transitions: [
                        AutomatonTransition(
                            startState: nil,
                            endState: nil,
                            currentSymbol: "A",
                            symbols: ["B", "C"],
                            scribblePosition: CGPoint(x: 200, y: 200),
                            stroke: Stroke(
                                controlPoints: .arrow(
                                    startPoint: CGPoint(x: 180, y: 200),
                                    tipPoint: CGPoint(x: 220, y: 200)
                                )
                            )
                        )
                    ]
                ),
                reducer: editorReducer,
                environment: EditorEnvironment(
                    automataClassifierService: .successfulTransition,
                    automataLibraryService: .successful(),
                    mainQueue: DispatchQueue.main.eraseToAnyScheduler()
                )
            )
        )
    }
}

