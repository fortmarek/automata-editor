import ComposableArchitecture
import CoreGraphics
import PencilKit
import CoreML

typealias EditorStore = Store<EditorState, EditorAction>
typealias EditorViewStore = ViewStore<EditorState, EditorAction>

struct EditorEnvironment {}

struct EditorState: Equatable {
    var automatonStates: [AutomatonState] = []
    var transitions: [Transition] = []
    var strokes: [Stroke] {
        automatonStates.map(\.stroke) + transitions.map(\.stroke)
    }
    var scribblePositions: [CGPoint] {
        automatonStates.map(\.scribblePosition)
    }
    var shouldDeleteLastStroke = false
}

enum EditorAction: Equatable {
    case clear
    case stateSymbolChanged(AutomatonState, String)
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

        state.automatonStates.append(
            AutomatonState(
                scribblePosition: center,
                stroke: Stroke(controlPoints: controlPoints)
            )
        )
    }
    
    switch action {
    case .clear:
        state.automatonStates = []
        state.transitions = []
    case let .stateSymbolChanged(automatonState, symbol):
        guard
            let automatonIndex = state.automatonStates.firstIndex(where: { $0.id == automatonState.id })
        else { return .none }
        state.automatonStates[automatonIndex].symbol = symbol
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
            guard
                let strokeStartPoint = stroke.controlPoints.first
            else { return .none }
            
            let (closestStartState, closestStartStatePoint, _): (AutomatonState?, CGPoint, CGFloat) = state.automatonStates.reduce((nil, .zero, CGFloat.infinity)) { acc, currentState in
                let closestPoint = currentState.stroke.controlPoints.reduce((CGPoint.zero, CGFloat.infinity)) { acc, current in
                    let currentDistance = (pow(strokeStartPoint.x - current.x, 2) + pow(strokeStartPoint.y - current.y, 2))
                    return currentDistance < acc.1 ? (current, currentDistance) : acc
                }
                .0
                let currentDistance = (pow(strokeStartPoint.x - closestPoint.x, 2) + pow(strokeStartPoint.y - closestPoint.y, 2))
                return currentDistance < acc.2 ? (currentState, closestPoint, currentDistance) : acc
            }
            
            
            let startPoint: CGPoint
            if let closestStartState = closestStartState {
                startPoint = closestStartStatePoint
            } else {
                startPoint = strokeStartPoint
            }
            
            let tipPoint: CGPoint = stroke.controlPoints.reduce((CGPoint.zero, CGFloat(0))) { acc, current in
                let currentDistance = (pow(startPoint.x - current.x, 2) + pow(startPoint.y - current.y, 2))
                return currentDistance > acc.1 ? (current, currentDistance) : acc
            }
            .0
            
            state.transitions.append(
                Transition(
                    startState: closestStartState,
                    endState: nil,
                    stroke: Stroke(
                        controlPoints: [
                            startPoint,
                            tipPoint,
                            CGPoint(x: tipPoint.x - 0.1, y: tipPoint.y + 0.1),
                            CGPoint(x: tipPoint.x - 1, y: tipPoint.y + 1),
                            CGPoint(x: tipPoint.x - 20, y: tipPoint.y + 30),
                            CGPoint(x: tipPoint.x - 20, y: tipPoint.y + 30),
                            tipPoint,
                            CGPoint(x: tipPoint.x - 0.1, y: tipPoint.y - 0.1),
                            CGPoint(x: tipPoint.x - 1, y: tipPoint.y - 1),
                            CGPoint(x: tipPoint.x - 20, y: tipPoint.y - 30),
                            CGPoint(x: tipPoint.x - 20, y: tipPoint.y - 30),
                        ]
                    )
                )
            )
            
        } else {
            state.shouldDeleteLastStroke = true
        }
    case let .shouldDeleteLastStrokeChanged(shouldDeleteLastStroke):
        state.shouldDeleteLastStroke = shouldDeleteLastStroke
    }
    
    return .none
}
