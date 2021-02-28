import SwiftUI
import Vision
import PencilKit
import ComposableArchitecture

struct AutomatonState: Equatable, Identifiable {
    var symbol: String = ""
    let scribblePosition: CGPoint
    let stroke: Stroke
    
    var id: Stroke {
        stroke
    }
}

struct Transition: Equatable {
    let startState: AutomatonState?
    let endState: AutomatonState?
    let symbol: String = ""
    let stroke: Stroke
}

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
                                get: { $0.automatonStates.first(where: { $0.id == automatonState.id })?.symbol ?? "" },
                                send: { .stateSymbolChanged(automatonState, $0) }
                            )
                        )
                        .border(colorScheme == .dark ? Color.white : Color.black)
                        .frame(width: 100, height: 30)
                        .position(automatonState.scribblePosition)
                    }

                }
                HStack {
                    Button("Clear") {
                        viewStore.send(.clear)
                    }
                    Button("Export") {
                        export()
                        canvasView.drawing = PKDrawing()
                    }
                }
            }
        }
    }
    
    private func export() {
        let image = canvasView.drawing.image(
            from: canvasView.drawing.bounds,
            scale: 1.0
        )
        .modelImage()!
        savePNG(image)
    }
    
    func savePNG(_ image: UIImage) {
        guard
            let pngData = image.pngData(),
            let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                .first?
                .appendingPathComponent("\(UUID().uuidString).png")
        else { return }
        try! pngData.write(to: path)
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        EditorView(
            store: EditorStore(
                initialState: .init(),
                reducer: editorReducer,
                environment: EditorEnvironment(
                    automataClassifierService: .successfulTransition,
                    mainQueue: DispatchQueue.main.eraseToAnyScheduler()
                )
            )
        )
    }
}
