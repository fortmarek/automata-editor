import ComposableArchitecture
import CoreGraphics
import PencilKit
import CoreML

typealias EditorStore = Store<EditorState, EditorAction>
typealias EditorViewStore = ViewStore<EditorState, EditorAction>

struct EditorEnvironment {}

struct EditorState: Equatable {
    var strokes: [Stroke] = []
    var shouldDeleteLastStroke = false
}

enum EditorAction: Equatable {
    case clear
    case strokesChanged([Stroke])
    case shouldDeleteLastStrokeChanged(Bool)
}

let editorReducer = Reducer<EditorState, EditorAction, EditorEnvironment> { state, action, env in
    func drawCircle(from stroke: Stroke) {
        let (sumX, sumY, count): (CGFloat, CGFloat, CGFloat) = stroke.controlPoints
            .reduce((CGFloat(0), CGFloat(0), CGFloat(0))) { acc, current in
                (acc.0 + current.x, acc.1 + current.y, acc.2 + 1)
            }
        let center = CGPoint(x: sumX / count, y: sumY / count)

        let sumDistance = stroke.controlPoints
            .reduce(0) { acc, current in
                acc + abs(center.x - current.x) + abs(center.y - current.y)
            }
        let radius = sumDistance / count

        let controlPoints: [CGPoint] = stride(from: CGFloat(0), to: 362, by: 2).map { index in
            let radians = index * CGFloat.pi / 180

            return CGPoint(
                x: CGFloat(center.x + radius * cos(radians)),
                y: CGFloat(center.y + radius * sin(radians))
            )
        }

        state.strokes.append(
            Stroke(controlPoints: controlPoints)
        )
    }
    
    switch action {
    case .clear:
        state.strokes = []
    case let .strokesChanged(strokes):
        guard let stroke = strokes.last else { return .none }
        
        let image = PKDrawing(strokes: [stroke.pkStroke()])
            .image(
                from: stroke.pkStroke().renderBounds,
                scale: 1.0
            )
        .modelImage()!

        let input = try! AutomataClassifierInput(drawingWith: image.cgImage!)
        let classifier = try! AutomataClassifier(configuration: MLModelConfiguration())
        let prediction = try! classifier.prediction(input: input)
        print(prediction.labelProbability)
        
        if prediction.label == "circle" {
            drawCircle(from: stroke)
        } else if prediction.label == "arrow" {
            // TODO: Implement drawing of arrow
            state.shouldDeleteLastStroke = true
        } else {
            state.shouldDeleteLastStroke = true
        }
    case let .shouldDeleteLastStrokeChanged(shouldDeleteLastStroke):
        state.shouldDeleteLastStroke = shouldDeleteLastStroke
    }
    
    return .none
}
