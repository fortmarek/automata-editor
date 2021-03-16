import SwiftUI
import Vision
import PencilKit
import ComposableArchitecture

struct EditorView: View {
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
                        strokes: viewStore.binding(
                            get: \.strokes,
                            send: EditorAction.strokesChanged
                        ),
                        tool: viewStore.state.tool
                    )
                    ForEach(viewStore.automatonStates) { automatonState in
                        TextView(
                            text: viewStore.binding(
                                get: { $0.automatonStates.first(where: { $0.id == automatonState.id })?.name ?? "" },
                                send: { .stateSymbolChanged(automatonState.id, $0) }
                            )
                        )
                        .border(colorScheme == .dark ? Color.white : Color.black, width: 2)
                        .frame(width: 50, height: 30)
                        .position(automatonState.scribblePosition)
                        
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 30)
                            Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                                .frame(width: 25)
                        }
                        .position(automatonState.currentDragPoint)
                        .offset(
                            x: automatonState.dragPoint.x - automatonState.currentDragPoint.x,
                            y: automatonState.dragPoint.y - automatonState.currentDragPoint.y
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    viewStore.send(
                                        .stateDragPointChanged(
                                            automatonState.id,
                                            CGPoint(
                                                x: automatonState.currentDragPoint.x + value.translation.width,
                                                y: automatonState.currentDragPoint.y + value.translation.height
                                            )
                                        )
                                    )
                                }
                                .onEnded { value in
                                    viewStore.send(
                                        .stateDragPointFinishedDragging(
                                            automatonState.id,
                                            CGPoint(
                                                x: automatonState.currentDragPoint.x + value.translation.width,
                                                y: automatonState.currentDragPoint.y + value.translation.height
                                            )
                                        )
                                    )
                                }
                        )
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
                                TextView(
                                    text: viewStore.binding(
                                        get: { _ in transition.currentSymbol },
                                        send: { .transitionSymbolChanged(transition, $0) }
                                    )
                                )
                                .border(colorScheme == .dark ? Color.white : Color.black, width: 2)
                                .frame(width: 50, height: 30)
                                Button(
                                    action: { viewStore.send(.transitionSymbolAdded(transition)) }
                                ) {
                                    Image(systemName: "plus.circle.fill")
                                }
                            }
                        }
                        .position(transition.scribblePosition)
                    }
                    ForEach(viewStore.transitions) { transition in
                        if let currentFlexPoint = transition.currentFlexPoint,
                           let flexPoint = transition.flexPoint {
                            ZStack {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 30)
                                Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                                    .frame(width: 25)
                            }
                            .position(currentFlexPoint)
                            .offset(x: flexPoint.x - currentFlexPoint.x, y: flexPoint.y - currentFlexPoint.y)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        viewStore.send(
                                            .transitionFlexPointChanged(
                                                transition.id,
                                                CGPoint(
                                                    x: currentFlexPoint.x + value.translation.width,
                                                    y: currentFlexPoint.y + value.translation.height
                                                )
                                            )
                                        )
                                    }
                                    .onEnded { value in
                                        viewStore.send(
                                            .transitionFlexPointFinishedDragging(
                                                transition.id,
                                                CGPoint(
                                                    x: currentFlexPoint.x + value.translation.width,
                                                    y: currentFlexPoint.y + value.translation.height
                                                )
                                            )
                                        )
                                    }
                            )
                        }
                    }
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

