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
                CanvasView(canvasView: $canvasView)
                HStack {
                    Button("Detect") {
                        detect()
                    }
                    Button("Clear") {
                        canvasView.drawing = PKDrawing()
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
    
    private func detect() {
        let image = canvasView.drawing.image(
            from: canvasView.drawing.bounds,
            scale: 1.0
        )
        .modelImage()!

        let input = try! AutomataClassifierInput(drawingWith: image.cgImage!)
        let classifier = try! AutomataClassifier(configuration: MLModelConfiguration())
        let prediction = try! classifier.prediction(input: input)
        print(prediction.labelProbability)
        
        guard prediction.label == "circle" else {
            canvasView.drawing = PKDrawing()
            return
        }
        
        let lastStroke = canvasView.drawing.strokes[canvasView.drawing.strokes.endIndex - 1]
        let (sumX, sumY, count) = lastStroke.path.interpolatedPoints(by: .distance(50))
            .reduce((CGFloat(0), CGFloat(0), CGFloat(0))) { acc, current in
                (acc.0 + current.location.x, acc.1 + current.location.y, acc.2 + 1)
            }
        let center = CGPoint(x: sumX / count, y: sumY / count)
        
        let sumDistance = lastStroke.path.interpolatedPoints(by: .distance(50))
            .reduce(0) { acc, current in
                acc + abs(center.x - current.location.x) + abs(center.y - current.location.y)
            }
        let radius = sumDistance / count

        let controlPoints: [PKStrokePoint] = stride(from: CGFloat(0), to: 362, by: 2).map { index in
            let radians = index * CGFloat.pi / 180
            
            let location = CGPoint(
                x: CGFloat(center.x + radius * cos(radians)),
                y: CGFloat(center.y + radius * sin(radians))
            )
            return strokePoint(location)
        }
        
        let strokePath = PKStrokePath(
            controlPoints: controlPoints,
            creationDate: Date()
        )
        let stroke = PKStroke(ink: PKInk(.pen), path: strokePath)
        
        canvasView.drawing.strokes[canvasView.drawing.strokes.endIndex - 1] = stroke
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

