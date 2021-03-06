import ComposableArchitecture
import CoreGraphics
import PencilKit
import CoreML
import SwiftAutomataLibrary
import SwiftUI
import UniformTypeIdentifiers

typealias EditorStore = Store<EditorState, EditorAction>
typealias EditorViewStore = ViewStore<EditorState, EditorAction>

extension UTType {
  static let automatonDocument = UTType(exportedAs: "marekfort.AutomataEditor.automaton")
}


// MARK: - Environment

struct EditorEnvironment {
    let automataClassifierService: AutomataClassifierService
    let automataLibraryService: AutomataLibraryService
    let shapeService: ShapeService
    let idFactory: IDFactory
    let mainQueue: AnySchedulerOf<DispatchQueue>
}

// MARK: - State

struct EditorState: Equatable, Codable {
    init(
        id: UUID = UUID(),
        tool: Tool = .pen,
        isEraserSelected: Bool = false,
        isPenSelected: Bool = true,
        outputString: String = "",
        input: String = "",
        automatonStatesDict: [AutomatonState.ID : AutomatonState] = [:],
        transitionsDict: [AutomatonTransition.ID : AutomatonTransition] = [:],
        shouldDeleteLastStroke: Bool = false
    ) {
        self.id = id
        self.tool = tool
        self.isEraserSelected = isEraserSelected
        self.isPenSelected = isPenSelected
        self.outputString = outputString
        self.input = input
        self.automatonStatesDict = automatonStatesDict
        self.transitionsDict = transitionsDict
        self.shouldDeleteLastStroke = shouldDeleteLastStroke
    }
    
    let id: UUID
    var tool: Tool = .pen
    var isEraserSelected: Bool = false
    var isPenSelected: Bool = true
    var outputString: String = ""
    var input: String = ""
    var automatonStatesDict: [AutomatonState.ID: AutomatonState] = [:]
    var transitionsDict: [AutomatonTransition.ID: AutomatonTransition] = [:]
    var shouldDeleteLastStroke = false
}

extension EditorState {
    var automatonStates: [AutomatonState] {
        automatonStatesDict.map(\.value)
    }
    var transitions: [AutomatonTransition] {
        transitionsDict.map(\.value)
    }
    var strokes: [Stroke] {
        automatonStates.map {
            Stroke(controlPoints: .circle(center: $0.center, radius: $0.radius))
        }
        + automatonStates.compactMap {
            guard $0.isFinalState else { return nil }
            return Stroke(
                controlPoints: .circle(
                    center: $0.center,
                    radius: $0.radius * 0.9
                )
            )
        }
        + transitions.map(\.stroke)
    }
    
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
        automatonStates.filter(\.isFinalState)
    }
}

extension EditorState: FileDocument {
    static var readableContentTypes: [UTType] { [.automatonDocument] }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
          throw CocoaError(.fileReadCorruptFile)
        }
        self = try JSONDecoder().decode(Self.self, from: data)
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try JSONEncoder().encode(self)
        return .init(regularFileWithContents: data)
    }
}

// MARK: - Action

enum EditorAction: Equatable {
    case clear
    case selectedEraser
    case selectedPen
    case removeLastInputSymbol
    case inputChanged(String)
    case simulateInput
    case simulateInputResult(Result<Empty, AutomataLibraryError>)
    case stateSymbolChanged(AutomatonState.ID, String)
    case stateDragPointFinishedDragging(AutomatonState.ID, CGPoint)
    case stateDragPointChanged(AutomatonState.ID, CGPoint)
    case toggleEpsilonInclusion(AutomatonTransition.ID)
    case transitionFlexPointFinishedDragging(AutomatonTransition.ID, CGPoint)
    case transitionFlexPointChanged(AutomatonTransition.ID, CGPoint)
    case transitionSymbolChanged(AutomatonTransition.ID, String)
    case transitionSymbolAdded(AutomatonTransition.ID)
    case transitionSymbolRemoved(AutomatonTransition.ID, String)
    case strokesChanged([Stroke])
    case shouldDeleteLastStrokeChanged(Bool)
    case automataShapeClassified(Result<AutomatonShape, AutomataClassifierError>)
}

// MARK: - Reducer

let editorReducer = Reducer<EditorState, EditorAction, EditorEnvironment> { state, action, env in
    // MARK: - Helpers
    struct ClosestStateResult {
        let state: AutomatonState
        let point: CGPoint
        let distance: CGFloat
    }
    /// - Returns: Closest automaton state, if exists, from a given `point`
    func closestState(from point: CGPoint) -> ClosestStateResult? {
        let result: (AutomatonState?, CGPoint, CGFloat) = state.automatonStates.reduce((nil, .zero, CGFloat.infinity)) { acc, currentState in
            let closestPoint: CGPoint = stroke(for: currentState).controlPoints.closestPoint(from: point)
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
    
    /// - Returns: Stroke for `automatonState` using `shapeService`
    func stroke(for automatonState: AutomatonState) -> Stroke {
        return Stroke(
            controlPoints: env.shapeService.circle(
                automatonState.center,
                automatonState.radius
            )
        )
    }
    
    /// - Returns: State that encapsulates `controlPoints`
    func enclosingState(for controlPoints: [CGPoint]) -> AutomatonState? {
        guard
            let minX = controlPoints.min(by: { $0.x < $1.x })?.x,
            let maxX = controlPoints.max(by: { $0.x < $1.x })?.x,
            let minY = controlPoints.min(by: { $0.y < $1.y })?.y,
            let maxY = controlPoints.max(by: { $0.y < $1.y })?.y
        else { return nil }
        return state.automatonStates.first(
            where: {
                CGRect(
                    x: minX,
                    y: minY,
                    width: maxX - minX,
                    height: maxY - minY
                )
                .contains($0.center) || CGPoint(x: minX, y: minY) == $0.center
            }
        )
    }
    
    /// - Returns: Closest transition for array of `controlPoints` that does not have an end state. Nil if none pases a threshold.
    func closestTransitionWithoutEndState(
        for controlPoints: [CGPoint]
    ) -> AutomatonTransition? {
        state.transitionsWithoutEndState.first(
            where: {
                switch $0.type {
                case .cycle:
                    return false
                case let .regular(
                    startPoint: _,
                    tipPoint: tipPoint,
                    flexPoint: _
                ):
                    return sqrt(controlPoints.closestPoint(from: tipPoint).distance(from: tipPoint)) < 40
                }
            }
        )
    }
    
    /// - Returns: Closest transition for array of `controlPoints` that does not have a start state. Nil if none pases a threshold.
    func closestTransitionWithoutStartState(
        for controlPoints: [CGPoint]
    ) -> AutomatonTransition? {
        state.transitionsWithoutStartState
            .first(
                where: {
                    switch $0.type {
                    case .cycle:
                        return false
                    case let .regular(
                        startPoint: startPoint,
                        tipPoint: _,
                        flexPoint: _
                    ):
                        return sqrt(controlPoints.closestPoint(from: startPoint).distance(from: startPoint)) < 40
                    }
                }
            )
    }

    func updateOutcomingTransitionsAfterStateDragged(_ automatonStateID: AutomatonState.ID) {
        state.transitions
            .filter { $0.endState == automatonStateID && $0.endState != $0.startState }
            .forEach { transition in
                guard
                    let flexPoint = transition.flexPoint,
                    let endStateID = transition.endState,
                    let endState = state.automatonStatesDict[endStateID]
                else { return }
                let vector = Vector(endState.center, flexPoint)
                // Closest intersection point between flex point and end state
                state.transitionsDict[transition.id]?.tipPoint = vector.point(distance: endState.radius, other: endState.center)
            }
    }
    
    func updateIncomingTransitionsAfterStateDragged(_ automatonStateID: AutomatonState.ID) {
        state.transitions
            .filter { $0.startState == automatonStateID && $0.endState != $0.startState }
            .forEach { transition in
                guard
                    let flexPoint = transition.flexPoint,
                    let startStateID = transition.startState,
                    let startState = state.automatonStatesDict[startStateID]
                else { return }
                let vector = Vector(startState.center, flexPoint)
                // Closest intersection point between flex point and start state
                state.transitionsDict[transition.id]?.startPoint = vector.point(distance: startState.radius, other: startState.center)
            }
    }
    
    func updateCyclesAfterStateDragged(_ automatonStateID: AutomatonState.ID) {
        state.transitions
            .forEach { transition in
                switch transition.type {
                case let .cycle(_, center: center, radians: radians):
                    guard
                        let endStateID = transition.endState,
                        let endState = state.automatonStatesDict[endStateID]
                    else { return }
                    let vector = Vector(
                        endState.center,
                        CGPoint(
                            x: endState.center.x,
                            y: endState.center.y + endState.radius
                        )
                    )
                    // We use saved rotation and apply to the new center of a dragged state.
                    .rotated(by: radians)
                    state.transitionsDict[transition.id]?.type = .cycle(
                        vector.point(distance: endState.radius, other: endState.center),
                        center: endState.center,
                        radians: radians
                    )
                case .regular:
                    break
                }
            }
    }
    
    /// Transitions must be updated after a state is dragged if they were connected to it.
    func updateTransitionsAfterStateDragged(_ automatonStateID: AutomatonState.ID) {
        updateOutcomingTransitionsAfterStateDragged(automatonStateID)
        updateIncomingTransitionsAfterStateDragged(automatonStateID)
        updateCyclesAfterStateDragged(automatonStateID)
    }
    
    func deleteStroke(from strokes: [Stroke]) {
        let centerPoints = strokes
            .map(\.controlPoints)
            .map(env.shapeService.center)
        // Find closest transition and delete it if it passes a given threshold
        if let transition = state.transitions.first(
            where: { transition in
                !strokes.contains(
                    where: { stroke in
                        switch transition.type {
                        case let .cycle(point, center: _, radians: _):
                            return point.distance(from: stroke.controlPoints[0]) <= 0.1
                        case let .regular(startPoint, tipPoint, flexPoint):
                            return startPoint.distance(from: stroke.controlPoints[0]) <= 0.1
                        }
                    }
                )
            }
        ) {
            state.transitionsDict.removeValue(forKey: transition.id)
        // Find closest automaton state to delete that passes a given threshold
        } else if let automatonState = state.automatonStates.first(
            where: { state in
                !centerPoints.contains(
                    where: {
                        sqrt(state.center.distance(from: $0)) < 20
                    }
                )
            }
        ) {
            state.automatonStatesDict.removeValue(forKey: automatonState.id)
            state.transitions.forEach { transition in
                var transition = transition
                switch transition.type {
                case .cycle:
                    if let transitionStartState = transition.startState,
                       transitionStartState == automatonState.id {
                        state.transitionsDict.removeValue(forKey: transition.id)
                    }
                case .regular:
                    if transition.startState == automatonState.id {
                        transition.startState = nil
                    }
                    if transition.endState == automatonState.id {
                        transition.endState = nil
                    }
                    state.transitionsDict[transition.id] = transition
                }
            }
        }
    }
    
    func updateDraggedTransition(_ transition: AutomatonTransition, flexPoint: CGPoint) {
        var transition = transition
        transition.flexPoint = flexPoint
        if
            transition.isInitialTransition,
            let tipPoint = transition.tipPoint {
            let vector = Vector(tipPoint, flexPoint)
            // Recompute start point for initial transitions.
            // Otherwise transition's start point can only be changed with a connected state
            transition.startPoint = vector.point(distance: sqrt(vector.lengthSquared), other: flexPoint)
        }
        state.transitionsDict[transition.id] = transition
    }
    
    switch action {
    case .selectedEraser:
        state.tool = .eraser
        state.isEraserSelected = true
        state.isPenSelected = false
    case .selectedPen:
        state.tool = .pen
        state.isEraserSelected = false
        state.isPenSelected = true
    case .clear:
        state.input = ""
        state.outputString = ""
        state.automatonStatesDict = [:]
        state.transitionsDict = [:]
    case let .inputChanged(input):
        state.input = input
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
    case .removeLastInputSymbol:
        guard !state.input.isEmpty else { return .none }
        state.input.removeLast()
    case .simulateInput:
        guard
            let initialState = state.initialStates.first
        else {
            state.outputString = "??? No initial state"
            return .none
        }
        guard state.initialStates.count == 1 else {
            state.outputString = "??? Multiple initial states"
            return .none
        }
        guard
            state.automatonStates
                .map(\.name)
                .allSatisfy ({ !$0.isEmpty })
        else {
            state.outputString = "??? Unnamed states"
            return .none
        }
        let input = Array(state.input).map(String.init)
        // Create FA's alphabet based on symbols present in transitions
        let alphabetSymbols: [String] = Array(
            Set(
                state.transitions
                    .flatMap {
                        $0.symbols + ($0.currentSymbol.isEmpty ? [] : [$0.currentSymbol])
                    }
            )
        )
        guard
            input.allSatisfy(alphabetSymbols.contains)
        else {
            state.outputString = "??? Input symbols are not accepted by the automaton"
            return .none
        }
        return env.automataLibraryService.simulateInput(
            input,
            state.automatonStates,
            initialState,
            state.finalStates,
            alphabetSymbols,
            state.transitions
        )
        .receive(on: env.mainQueue)
        .map(Empty.init)
        .catchToEffect()
        .map(EditorAction.simulateInputResult)
        .eraseToEffect()
    case .simulateInputResult(.success):
        state.outputString = "???"
    case .simulateInputResult(.failure):
        state.outputString = "???"
    case let .stateSymbolChanged(automatonStateID, symbol):
        state.automatonStatesDict[automatonStateID]?.name = symbol
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
    case let .transitionSymbolChanged(transitionID, symbol):
        state.transitionsDict[transitionID]?.currentSymbol = symbol
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
    case let .transitionSymbolAdded(transitionID):
        guard
            let transition = state.transitionsDict[transitionID]
        else { return .none }
        state.transitionsDict[transitionID]?.symbols.append(
            transition.currentSymbol
        )
        state.transitionsDict[transitionID]?.currentSymbol = ""
    case let .transitionSymbolRemoved(transitionID, symbol):
        state.transitionsDict[transitionID]?.symbols.removeAll(where: { $0 == symbol })
    case let .automataShapeClassified(.success(.state(stateStroke))):
        let center = env.shapeService.center(stateStroke.controlPoints)
        let radius = env.shapeService.radius(stateStroke.controlPoints, center)
        
        let controlPoints: [CGPoint] = env.shapeService.circle(
            center,
            radius
        )
        
        // Make a state final if this is a double circle
        if let automatonState = enclosingState(for: controlPoints) {
            guard !automatonState.isFinalState else {
                state.shouldDeleteLastStroke = true
                return .none
            }
            let controlPoints = stroke(for: automatonState).controlPoints
            let center = env.shapeService.center(controlPoints)
            state.automatonStatesDict[automatonState.id]?.isFinalState = true
        // Connect to a transition without end state if one is close enough
        } else if var transition = closestTransitionWithoutEndState(for: controlPoints) {
            guard
                let startPoint = transition.startPoint,
                let tipPoint = transition.tipPoint
            else { return .none }
            let vector = Vector(startPoint, tipPoint)
            let center = vector.point(distance: radius, other: tipPoint)
            
            let automatonState = AutomatonState(
                id: env.idFactory.generateID(),
                center: center,
                radius: radius
            )
            
            transition.endState = automatonState.id
            state.transitionsDict[transition.id] = transition
            
            state.automatonStatesDict[automatonState.id] = automatonState
        // Connect to a transition without start state if one is close enough
        } else if var transition = closestTransitionWithoutStartState(for: controlPoints) {
            guard
                let startPoint = transition.startPoint,
                let tipPoint = transition.tipPoint
            else { return .none }
            let vector = Vector(tipPoint, startPoint)
            let center = vector.point(distance: radius, other: startPoint)
            
            let automatonState = AutomatonState(
                id: env.idFactory.generateID(),
                center: center,
                radius: radius
            )
            
            transition.startState = automatonState.id
            state.transitionsDict[transition.id] = transition
            
            state.automatonStatesDict[automatonState.id] = automatonState
        } else {
            let automatonState = AutomatonState(
                id: env.idFactory.generateID(),
                center: center,
                radius: radius
            )
            state.automatonStatesDict[automatonState.id] = automatonState
        }
    case let .transitionFlexPointFinishedDragging(transitionID, finalFlexPoint):
        guard var transition = state.transitionsDict[transitionID] else { return .none }
        /// Update `currentFlexPoint` only when dragging has finished
        transition.currentFlexPoint = finalFlexPoint
        updateDraggedTransition(transition, flexPoint: finalFlexPoint)
    case let .transitionFlexPointChanged(transitionID, flexPoint):
        guard var transition = state.transitionsDict[transitionID] else { return .none }
        updateDraggedTransition(transition, flexPoint: flexPoint)
    case let .stateDragPointChanged(automatonStateID, dragPoint):
        state.automatonStatesDict[automatonStateID]?.dragPoint = dragPoint
        updateTransitionsAfterStateDragged(automatonStateID)
    case let .stateDragPointFinishedDragging(automatonStateID, dragPoint):
        state.automatonStatesDict[automatonStateID]?.dragPoint = dragPoint
        state.automatonStatesDict[automatonStateID]?.currentDragPoint = dragPoint
        updateTransitionsAfterStateDragged(automatonStateID)
    case let .toggleEpsilonInclusion(transitionID):
        state.transitionsDict[transitionID]?.includesEpsilon.toggle()
    case let .automataShapeClassified(.success(.transitionCycle(cycleStroke))):
        guard
            let strokeStartPoint = cycleStroke.controlPoints.first,
            let closestStateResult = closestState(from: strokeStartPoint)
        else {
            state.shouldDeleteLastStroke = true
            return .none
        }
        
        let cycleControlPoints: [CGPoint] = .cycle(
            closestStateResult.point,
            center: closestStateResult.state.center
        )
        let highestPoint = cycleControlPoints.min(by: { $0.y < $1.y }) ?? .zero

        let center = closestStateResult.state.center
        // Angle between vector of center to topmost state's point and vector from center to the cycle's intersection point with the state.
        let radians = Vector(
            center,
            CGPoint(
                x: center.x,
                y: center.y + closestStateResult.state.radius
            )
        )
        .angle(
            with: Vector(
                center,
                closestStateResult.point
            )
        )
        
        let transition = AutomatonTransition(
            id: env.idFactory.generateID(),
            startState: closestStateResult.state.id,
            endState: closestStateResult.state.id,
            type: .cycle(
                closestStateResult.point,
                center: center,
                radians: radians
            )
        )
        state.transitionsDict[transition.id] = transition
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
        // Connect transition to start or end state if any exists.
        // If both exist, then connect it to the closer one.
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
        
        let flexPoint = CGPoint(
            x: (startPoint.x + tipPoint.x) / 2,
            y: (startPoint.y + tipPoint.y) / 2
        )
        
        let transition = AutomatonTransition(
            id: env.idFactory.generateID(),
            startState: startState?.id,
            endState: endState?.id,
            type: .regular(
                startPoint: startPoint,
                tipPoint: tipPoint,
                flexPoint: flexPoint
            ),
            currentFlexPoint: flexPoint
        )
        state.transitionsDict[transition.id] = transition
    case .automataShapeClassified(.failure):
        state.shouldDeleteLastStroke = true
    case let .strokesChanged(strokes):
        // A stroke was deleted
        if strokes.count < state.strokes.count {
            deleteStroke(from: strokes)
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
