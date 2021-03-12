import ComposableArchitecture
import CoreGraphics
import PencilKit
import CoreML
import SwiftAutomataLibrary
import SwiftUI

typealias EditorStore = Store<EditorState, EditorAction>
typealias EditorViewStore = ViewStore<EditorState, EditorAction>

struct EditorEnvironment {
    let automataClassifierService: AutomataClassifierService
    let automataLibraryService: AutomataLibraryService
    let mainQueue: AnySchedulerOf<DispatchQueue>
}

struct EditorState: Equatable {
    var tool: Tool = .pen
    var eraserImage: Image = Image(systemName: "minus.square")
    var penImage: Image = Image(systemName: "pencil.circle.fill")
    var outputString: String = ""
    var input: String = ""
    var currentAlphabetSymbol: String = ""
    var alphabetSymbols: [String] = []
    var automatonStates: [AutomatonState] = []
    var transitions: [AutomatonTransition] = []
    var strokes: [Stroke] {
        automatonStates.map(\.stroke) + automatonStates.compactMap(\.endStroke) + transitions.map(\.stroke)
    }
    var scribblePositions: [CGPoint] {
        automatonStates.map(\.scribblePosition) + transitions.map(\.scribblePosition)
    }
    var shouldDeleteLastStroke = false
    
    fileprivate var transitionsWithoutEndState: [AutomatonTransition] {
        transitions.filter { $0.endState == nil }
    }
    
    fileprivate var transitionsWithoutStartState: [AutomatonTransition] {
        transitions.filter { $0.startState == nil }
    }
    
    fileprivate var initialStates: [AutomatonState] {
        transitionsWithoutStartState
            .compactMap(\.endState)
            .compactMap { stateID in
                automatonStates.first(where: { $0.id == stateID })
            }
    }
    
    fileprivate var finalStates: [AutomatonState] {
        automatonStates.filter { $0.endStroke != nil }
    }
}

enum EditorAction: Equatable {
    case clear
    case selectedEraser
    case selectedPen
    case currentAlphabetSymbolChanged(String)
    case addedCurrentAlphabetSymbol
    case removedAlphabetSymbol(String)
    case inputChanged(String)
    case simulateInput(String)
    case simulateInputResult(Result<[AutomatonState], AutomataLibraryError>)
    case stateSymbolChanged(AutomatonState.ID, String)
    case transitionSymbolChanged(AutomatonTransition, String)
    case transitionSymbolAdded(AutomatonTransition)
    case transitionSymbolRemoved(AutomatonTransition, String)
    case strokesChanged([Stroke])
    case shouldDeleteLastStrokeChanged(Bool)
    case automataShapeClassified(Result<AutomatonShape, AutomataClassifierError>)
}

let editorReducer = Reducer<EditorState, EditorAction, EditorEnvironment> { state, action, env in
    struct ClosestStateResult {
        let state: AutomatonState
        let point: CGPoint
        let distance: CGFloat
    }
    func closestState(from point: CGPoint) -> ClosestStateResult? {
        let result: (AutomatonState?, CGPoint, CGFloat) = state.automatonStates.reduce((nil, .zero, CGFloat.infinity)) { acc, currentState in
            let closestPoint = currentState.stroke.controlPoints.closestPoint(from: point)
            let currentDistance = closestPoint.distance(from: point)
            return currentDistance < acc.2 ? (currentState, closestPoint, currentDistance) : acc
        }
        
        if let state = result.0 {
            return ClosestStateResult(
                state: state,
                point: result.1,
                distance: result.2
            )
        } else {
            return nil
        }
    }
    
    switch action {
    case .selectedEraser:
        state.tool = .eraser
        state.eraserImage = Image(systemName: "minus.square.fill")
        state.penImage = Image(systemName: "pencil.circle")
    case .selectedPen:
        state.tool = .pen
        state.eraserImage = Image(systemName: "minus.square")
        state.penImage = Image(systemName: "pencil.circle.fill")
    case let .currentAlphabetSymbolChanged(symbol):
        state.currentAlphabetSymbol = symbol
    case let .removedAlphabetSymbol(symbol):
        state.alphabetSymbols.removeAll(where: { $0 == symbol })
    case .addedCurrentAlphabetSymbol:
        state.alphabetSymbols.append(state.currentAlphabetSymbol)
        state.currentAlphabetSymbol = ""
    case .clear:
        state.automatonStates = []
        state.transitions = []
    case let .inputChanged(input):
        state.input = input
    case let .simulateInput(input):
        // TODO: Handle no or multiple initial states
        guard let initialStates = state.initialStates.first else { return .none }
        return env.automataLibraryService.simulateInput(
            input,
            state.automatonStates,
            initialStates,
            state.finalStates,
            state.alphabetSymbols,
            state.transitions
        )
        .receive(on: env.mainQueue)
        .catchToEffect()
        .map(EditorAction.simulateInputResult)
        .eraseToEffect()
    case let .simulateInputResult(.success(endStates)):
        state.outputString = "✅ with states: \(endStates)"
    case let .simulateInputResult(.failure(endStates)):
        state.outputString = "❌ with states: \(endStates)"
    case let .stateSymbolChanged(automatonStateID, symbol):
        guard
            let automatonIndex = state.automatonStates.firstIndex(where: { $0.id == automatonStateID })
        else { return .none }
        state.automatonStates[automatonIndex].name = symbol
    case let .transitionSymbolChanged(transition, symbol):
        guard
            let transitionIndex = state.transitions.firstIndex(where: { $0.id == transition.id })
        else { return .none }
        state.transitions[transitionIndex].currentSymbol = symbol
    case let .transitionSymbolAdded(transition):
        guard
            let transitionIndex = state.transitions.firstIndex(where: { $0.id == transition.id })
        else { return .none }
        state.transitions[transitionIndex].currentSymbol = ""
        state.transitions[transitionIndex].symbols.append(transition.currentSymbol)
    case let .transitionSymbolRemoved(transition, symbol):
        guard
            let transitionIndex = state.transitions.firstIndex(where: { $0.id == transition.id })
        else { return .none }
        state.transitions[transitionIndex].symbols.removeAll(where: { $0 == symbol })
    case let .automataShapeClassified(.success(.state(stroke))):
        let center = stroke.controlPoints.center()

        let radius = stroke.controlPoints.radius(with: center)

        let controlPoints: [CGPoint] = .circle(
            center: center,
            radius: radius
        )
        
        if
            let minX = controlPoints.min(by: { $0.x < $1.x })?.x,
            let maxX = controlPoints.max(by: { $0.x < $1.x })?.x,
            let minY = controlPoints.min(by: { $0.y < $1.y })?.y,
            let maxY = controlPoints.max(by: { $0.y < $1.y })?.y,
            let stateIndex = state.automatonStates.firstIndex(
                where: {
                    CGRect(
                        x: minX,
                        y: minY,
                        width: maxX - minX,
                        height: maxY - minY
                    )
                    .contains($0.stroke.controlPoints.center())
                }
            ) {
            guard state.automatonStates[stateIndex].endStroke == nil else {
                state.shouldDeleteLastStroke = true
                return .none
            }
            let controlPoints = state.automatonStates[stateIndex].stroke.controlPoints
            let center = controlPoints.center()
            state.automatonStates[stateIndex].endStroke = Stroke(
                controlPoints: .circle(
                    center: center,
                    radius: controlPoints.radius(with: center) * 0.7
                )
            )
        } else {
            state.automatonStates.append(
                AutomatonState(
                    scribblePosition: center,
                    stroke: Stroke(controlPoints: controlPoints)
                )
            )
        }
    case let .automataShapeClassified(.success(.transition(stroke))):
        guard
            let strokeStartPoint = stroke.controlPoints.first
        else { return .none }
        
        let closestStartStateResult = closestState(from: strokeStartPoint)
        
        let furthestPoint = stroke.controlPoints.furthestPoint(from: closestStartStateResult?.point ?? strokeStartPoint)
        let closestEndStateResult = closestState(
            from: furthestPoint
        )
        
        let startPoint: CGPoint
        let tipPoint: CGPoint
        let startState: AutomatonState?
        let endState: AutomatonState?
        if
            let closestStartStateResult = closestStartStateResult,
            let closestEndStateResult = closestEndStateResult,
            closestStartStateResult.state == closestEndStateResult.state {
            let startIsCloser = closestStartStateResult.distance < closestEndStateResult.distance
            startPoint = startIsCloser ? closestStartStateResult.point : strokeStartPoint
            tipPoint = startIsCloser ? furthestPoint : closestEndStateResult.point
            startState = startIsCloser ? closestStartStateResult.state : nil
            endState = startIsCloser ? nil : closestEndStateResult.state
        } else {
            startPoint = closestStartStateResult?.point ?? strokeStartPoint
            tipPoint = closestEndStateResult?.point ?? furthestPoint
            startState = closestStartStateResult?.state
            endState = closestEndStateResult?.state
        }
        
        state.transitions.append(
            AutomatonTransition(
                startState: startState?.id,
                endState: endState?.id,
                scribblePosition: CGPoint(
                    x: (startPoint.x + tipPoint.x) / 2,
                    y: (startPoint.y + tipPoint.y) / 2 - 50
                ),
                stroke: Stroke(
                    controlPoints: .arrow(
                        startPoint: startPoint,
                        tipPoint: tipPoint
                    )
                )
            )
        )
    case .automataShapeClassified(.failure):
        state.shouldDeleteLastStroke = true
    case let .strokesChanged(strokes):
        // A stroke was deleted
        if strokes.count < state.strokes.count {
            if let automatonStateIndex = state.automatonStates.firstIndex(where: { !strokes.contains($0.stroke) }) {
                let automatonState = state.automatonStates[automatonStateIndex]
                state.automatonStates.remove(at: automatonStateIndex)
                state.transitions = state.transitions.map { transition in
                    var transition = transition
                    if transition.startState == automatonState.id {
                        transition.startState = nil
                    }
                    if transition.endState == automatonState.id {
                        transition.endState = nil
                    }
                    return transition
                }
            }
        } else {
            guard let stroke = strokes.last else { return .none }
            return env.automataClassifierService
                .recognizeStroke(stroke)
                .receive(on: env.mainQueue)
                .catchToEffect()
                .map(EditorAction.automataShapeClassified)
                .eraseToEffect()
        }
    case let .shouldDeleteLastStrokeChanged(shouldDeleteLastStroke):
        state.shouldDeleteLastStroke = shouldDeleteLastStroke
    }
    
    return .none
}

extension CGPoint {
    func distance(from other: CGPoint) -> CGFloat {
        pow(other.x - x, 2) + pow(other.y - y, 2)
    }
}

extension Array where Element == CGPoint {
    func closestPoint(from point: CGPoint) -> CGPoint {
        reduce((CGPoint.zero, CGFloat.infinity)) { acc, current in
            let currentDistance = current.distance(from: point)
            return currentDistance < acc.1 ? (current, currentDistance) : acc
        }
        .0
    }
    
    func furthestPoint(from point: CGPoint) -> CGPoint {
        reduce((CGPoint.zero, -CGFloat.infinity)) { acc, current in
            let currentDistance = current.distance(from: point)
            return currentDistance > acc.1 ? (current, currentDistance) : acc
        }
        .0
    }
    
    func center() -> CGPoint {
        let (sumX, sumY, count): (CGFloat, CGFloat, CGFloat) = reduce((CGFloat(0), CGFloat(0), CGFloat(0))) { acc, current in
                (acc.0 + current.x, acc.1 + current.y, acc.2 + 1)
            }
        return CGPoint(x: sumX / count, y: sumY / count)
    }
    
    func radius(with center: CGPoint) -> CGFloat {
        let sumDistance = reduce(0) { acc, current in
                acc + abs(center.x - current.x) + abs(center.y - current.y)
            }
        return sumDistance / CGFloat(count)
    }
}
