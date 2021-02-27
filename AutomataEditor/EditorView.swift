import SwiftUI
import Vision
import PencilKit
import ComposableArchitecture

struct AutomatonState {
    let symbol: String = ""
}

struct EditorView: View {
    @State var canvasView: PKCanvasView = .init()
    
    let store: EditorStore
    
    var body: some View {
        WithViewStore(store) { (viewStore: EditorViewStore) in
            VStack {
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        EditorView(
            store: EditorStore(
                initialState: .init(),
                reducer: editorReducer,
                // TODO: Change for mock environment
                environment: EditorEnvironment()
            )
        )
    }
}

