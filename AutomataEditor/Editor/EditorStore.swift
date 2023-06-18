import ComposableArchitecture
import CoreGraphics
import PencilKit
import CoreML
import SwiftAutomataLibrary
import SwiftUI
import UniformTypeIdentifiers

extension UTType {
  static let automatonDocument = UTType(exportedAs: "marekfort.AutomataEditor.automaton")
}

// MARK: - Environment

struct EditorEnvironment {
    let automataClassifierService: AutomataClassifierService
    let automataLibraryService: AutomataLibraryService
    let shapeService: ShapeService
    let undoService: UndoService
    let idFactory: IDFactory
    let mainQueue: AnySchedulerOf<DispatchQueue>
}

extension EditorFeature.State {
    var automatonStates: [AutomatonState] {
        automatonStatesDict.map(\.value)
    }
    var transitions: [AutomatonTransition] {
        transitionsDict.map(\.value)
    }
    
    fileprivate var transitionsWithoutEndState: [AutomatonTransition] {
        transitions.filter { $0.endState == nil }
    }
    
    fileprivate var transitionsWithoutStartState: [AutomatonTransition] {
        transitions.filter { $0.startState == nil }
    }
    
    var initialStates: [AutomatonState] {
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

// MARK: - Reducer

struct EditorFeature: ReducerProtocol {
    enum Mode: Equatable {
        case editing, addingTransition, erasing, addingCycle, addingFinalState, addingInitialState
    }
    
    struct State: Equatable {
        init(
            automatonURL: URL,
            id: UUID = UUID(),
            tool: Tool = .pen,
            isEraserSelected: Bool = false,
            isPenSelected: Bool = true,
            automatonOutput: AutomatonOutput = .success,
            input: String = "",
            automatonStatesDict: [AutomatonState.ID : AutomatonState] = [:],
            transitionsDict: [AutomatonTransition.ID : AutomatonTransition] = [:],
            shouldDeleteLastStroke: Bool = false
        ) {
            self.automatonURL = automatonURL
            self.id = id
            self.tool = tool
            self.isEraserSelected = isEraserSelected
            self.isPenSelected = isPenSelected
            self.automatonOutput = automatonOutput
            self.input = input
            self.automatonStatesDict = automatonStatesDict
            self.transitionsDict = transitionsDict
            self.shouldDeleteLastStroke = shouldDeleteLastStroke
        }
        
        let automatonURL: URL
        let id: UUID
        var tool: Tool = .pen
        var isEraserSelected: Bool = false
        var isPenSelected: Bool = true
        var input: String = ""
        var automatonStatesDict: [AutomatonState.ID: AutomatonState] = [:]
        var transitionsDict: [AutomatonTransition.ID: AutomatonTransition] = [:]
        var shouldDeleteLastStroke = false
        var viewSize: CGSize = .zero
        var mode: Mode = .editing
        var currentlySelectedStateForTransition: AutomatonState.ID?
        var currentVisibleScrollViewRect: CGRect?
        var isClearAlertPresented = false
        var automatonOutput: AutomatonOutput = .success
        var isAutomatonOutputVisible = false
        var canUndo = false
        var canRedo = false
    }
    
    enum AutomatonOutput: Equatable {
        case success
        case failure(String?)
    }
    
    
    enum Action: Equatable {
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
        case automatonStateRemoved(AutomatonState.ID)
        case transitionRemoved(AutomatonTransition.ID)
        case automataShapeClassified(Result<AutomatonShape, AutomataClassifierError>)
        case stateUpdated(State)
        case addNewState
        case viewSizeChanged(CGSize)
        case startAddingTransition
        case startAddingCycle
        case stopAddingCycle
        case stopAddingTransition
        case startAddingFinalState
        case stopAddingFinalState
        case startAddingInitialState
        case stopAddingInitialState
        case selectedInitialState(AutomatonState.ID)
        case selectedStateForTransition(AutomatonState.ID)
        case selectedStateForCycle(AutomatonState.ID)
        case selectedFinalState(AutomatonState.ID)
        case currentVisibleScrollViewRectChanged(CGRect)
        case clearButtonPressed
        case clearAlertDismissed
        case dismissToast
        case undo
        case redo
        case onAppear
        case addState(AutomatonState)
    }
    
    @Dependency(\.idFactory) var idFactory
    @Dependency(\.automataLibraryService) var automataLibraryService
    @Dependency(\.automataClassifierService) var automataClassifierService
    @Dependency(\.shapeService) var shapeService
    @Dependency(\.continuousClock) var clock
    @Dependency(\.undoService) var undoService
    private enum TimerID {}

    struct ClosestStateResult {
        let state: AutomatonState
        let point: CGPoint
        let distance: CGFloat
    }
    
    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
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
                controlPoints: shapeService.circle(
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
                    case let .cycle(_, center: _, radians: radians):
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
                .map(shapeService.center)
            // Find closest transition and delete it if it passes a given threshold
            if let transition = state.transitions.first(
                where: { transition in
                    !strokes.contains(
                        where: { stroke in
                            switch transition.type {
                            case let .cycle(point, center: _, radians: _):
                                return point.distance(from: stroke.controlPoints[0]) <= 0.1
                            case let .regular(startPoint, _, _):
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
        
        func showAutomatonOutput(_ automatonOutput: AutomatonOutput) -> EffectTask<Action> {
            state.automatonOutput = automatonOutput
            state.isAutomatonOutputVisible = true

            return .run { send in
                try await clock.sleep(for: .seconds(5))
                return await send(.dismissToast, animation: .spring())
            }
            .cancellable(id: TimerID.self, cancelInFlight: true)
        }
        
        func registerUndo(_ undoAction: Action) {
            undoService.registerUndo(undoAction)
            state.canUndo = undoService.canUndo()
            state.canRedo = undoService.canRedo()
        }
        
        switch action {
        case let .currentVisibleScrollViewRectChanged(currentVisibleScrollViewRect):
            state.currentVisibleScrollViewRect = currentVisibleScrollViewRect
        case let .addState(automatonState):
            state.automatonStatesDict[automatonState.id] = automatonState
            state.transitions.forEach { transition in
                state.transitionsDict[transition.id] = transition
            }
        case let .automatonStateRemoved(automatonStateID):
            guard let automatonState = state.automatonStatesDict[automatonStateID] else { return .none }
            if state.automatonStatesDict[automatonStateID]?.isFinalState == true {
                state.automatonStatesDict[automatonStateID]?.isFinalState = false
                return .none
            }
            state.automatonStatesDict.removeValue(forKey: automatonStateID)
            registerUndo(.addState(automatonState))
            state.transitions.forEach { transition in
                var transition = transition
                switch transition.type {
                case .cycle:
                    if let transitionStartState = transition.startState,
                       transitionStartState == automatonStateID {
                        state.transitionsDict.removeValue(forKey: transition.id)
                    }
                case .regular:
                    if transition.startState == automatonStateID {
                        transition.startState = nil
                    }
                    if transition.endState == automatonStateID {
                        transition.endState = nil
                    }
                    state.transitionsDict[transition.id] = transition
                }
            }
        case let .transitionRemoved(transitionID):
            state.transitionsDict.removeValue(forKey: transitionID)
        case .startAddingTransition:
            state.mode = .addingTransition
        case .startAddingInitialState:
            state.mode = .addingInitialState
        case .startAddingCycle:
            state.mode = .addingCycle
        case .stopAddingCycle, .stopAddingTransition, .stopAddingFinalState, .stopAddingInitialState:
            state.mode = state.isPenSelected ? .editing : .erasing
            state.currentlySelectedStateForTransition = nil
        case .startAddingFinalState:
            state.mode = .addingFinalState
        case let .selectedFinalState(automatonStateID):
            state.automatonStatesDict[automatonStateID]?.isFinalState = true
            state.mode = .editing
        case let .selectedStateForCycle(automatonStateID):
            guard let selectedState = state.automatonStatesDict[automatonStateID] else { return .none }

            let transition = AutomatonTransition(
                id: idFactory.generateID(),
                startState: automatonStateID,
                endState: automatonStateID,
                type: .cycle(
                    CGPoint(x: selectedState.center.x, y: selectedState.center.y - selectedState.radius),
                    center: selectedState.center,
                    radians: .pi
                )
            )
            state.transitionsDict[transition.id] = transition
            state.currentlySelectedStateForTransition = nil
            state.mode = .editing
        case let .selectedInitialState(automatonStateID):
            guard let initialState = state.automatonStatesDict[automatonStateID] else { return .none }
            let tipPoint = CGPoint(
                x: initialState.center.x - initialState.radius,
                y: initialState.center.y
            )
            let flexPoint = CGPoint(
                x: tipPoint.x - 50,
                y: tipPoint.y
            )
            let startPoint = CGPoint(
                x: tipPoint.x - 100,
                y: tipPoint.y
            )
                
            let transition = AutomatonTransition(
                id: idFactory.generateID(),
                startState: nil,
                endState: automatonStateID,
                type: .regular(
                    startPoint: startPoint,
                    tipPoint: tipPoint,
                    flexPoint: flexPoint
                ),
                currentFlexPoint: flexPoint
            )
            state.transitionsDict[transition.id] = transition
            state.mode = .editing
        case let .selectedStateForTransition(automatonStateID):
            if automatonStateID == state.currentlySelectedStateForTransition {
                state.currentlySelectedStateForTransition = nil
            } else if let currentlySelectedStateForTransition = state.currentlySelectedStateForTransition {
                guard
                    let startState = state.automatonStatesDict[currentlySelectedStateForTransition],
                    let endState = state.automatonStatesDict[automatonStateID]
                else { return .none }
                let startStateIntersection = Geometry.intersections(
                    pointA: startState.center,
                    pointB: endState.center,
                    circle: Geometry.Circle(center: startState.center, radius: startState.radius)
                )
                let endStateIntersection = Geometry.intersections(
                    pointA: startState.center,
                    pointB: endState.center,
                    circle: Geometry.Circle(center: endState.center, radius: endState.radius)
                )
                let shortestVector = [
                    (startStateIntersection.0, endStateIntersection.0),
                    (startStateIntersection.0, endStateIntersection.1),
                    (startStateIntersection.1, endStateIntersection.0),
                    (startStateIntersection.1, endStateIntersection.1),
                ]
                    .min(
                        by: { pointsA, pointsB in
                            return Vector(pointsA.0, pointsA.1).lengthSquared < Vector(pointsB.0, pointsB.1).lengthSquared
                        }
                    )
                guard
                    let shortestVector = shortestVector
                else { return .none }
                let (startPoint, tipPoint) = shortestVector
                let flexPoint = CGPoint(
                    x: (startState.center.x + endState.center.x) / 2,
                    y: (startState.center.y + endState.center.y) / 2
                )
                let transition = AutomatonTransition(
                    id: idFactory.generateID(),
                    startState: startState.id,
                    endState: endState.id,
                    type: .regular(
                        startPoint: startPoint,
                        tipPoint: tipPoint,
                        flexPoint: flexPoint
                    ),
                    currentFlexPoint: flexPoint
                )
                state.transitionsDict[transition.id] = transition
                state.currentlySelectedStateForTransition = nil
                state.mode = .editing
            } else {
                state.currentlySelectedStateForTransition = automatonStateID
            }
        case .addNewState:
            let center: CGPoint
            
            if let currentVisibleScrollViewRect = state.currentVisibleScrollViewRect {
                center = CGPoint(
                    x: currentVisibleScrollViewRect.origin.x + currentVisibleScrollViewRect.width / 2,
                    y: currentVisibleScrollViewRect.origin.y +  currentVisibleScrollViewRect.height * 0.5
                )
            } else {
                center = CGPoint(x: state.viewSize.width / 2, y: state.viewSize.height * 0.4)
            }
            
            let automatonState = AutomatonState(
                id: idFactory.generateID(),
                center: center,
                radius: 100
            )
            state.automatonStatesDict[automatonState.id] = automatonState
            registerUndo(.automatonStateRemoved(automatonState.id))
        case let .viewSizeChanged(viewSize):
            state.viewSize = viewSize
        case .stateUpdated:
            return .none
        case .selectedEraser:
            state.tool = .eraser
            state.mode = .erasing
            state.isEraserSelected = true
            state.isPenSelected = false
        case .selectedPen:
            state.tool = .pen
            state.mode = .editing
            state.isEraserSelected = false
            state.isPenSelected = true
        case .clear:
            state.input = ""
            state.isAutomatonOutputVisible = false
            state.automatonStatesDict = [:]
            state.transitionsDict = [:]
        case .clearButtonPressed:
            state.isClearAlertPresented = true
        case .clearAlertDismissed:
            state.isClearAlertPresented = false
        case let .inputChanged(input):
            state.input = input
                .replacingOccurrences(of: " ", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        case .removeLastInputSymbol:
            guard !state.input.isEmpty else { return .none }
            state.input.removeLast()
        case .simulateInput:
            guard
                let initialState = state.initialStates.first
            else {
                return showAutomatonOutput(.failure("No initial state"))
            }
            guard state.initialStates.count == 1 else {
                return showAutomatonOutput(.failure("Multiple initial states"))
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
                return showAutomatonOutput(.failure("Input symbols are not accepted by the automaton"))
            }
            let automatonStates = state.automatonStates
            let finalStates = state.finalStates
            let transitions = state.transitions
            return .task {
                do {
                    try automataLibraryService.simulateInput(
                        input,
                        automatonStates,
                        initialState,
                        finalStates,
                        alphabetSymbols,
                        transitions
                    )
                    return Action.simulateInputResult(.success(Empty()))
                } catch {
                    return Action.simulateInputResult(.failure(.failed))
                }
            }
        case .dismissToast:
            state.isAutomatonOutputVisible = false
        case .simulateInputResult(.success):
            return showAutomatonOutput(.success)
        case .simulateInputResult(.failure):
            return showAutomatonOutput(.failure(nil))
        case let .stateSymbolChanged(automatonStateID, symbol):
            state.automatonStatesDict[automatonStateID]?.name = symbol
                .replacingOccurrences(of: " ", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        case let .transitionSymbolChanged(transitionID, symbol):
            state.transitionsDict[transitionID]?.currentSymbol = symbol
                .replacingOccurrences(of: " ", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        case let .transitionSymbolAdded(transitionID):
            guard
                let transition = state.transitionsDict[transitionID],
                !transition.currentSymbol.isEmpty,
                !transition.symbols.contains(transition.currentSymbol)
            else { return .none }
            state.transitionsDict[transitionID]?.symbols.append(
                transition.currentSymbol
            )
            state.transitionsDict[transitionID]?.currentSymbol = ""
        case let .transitionSymbolRemoved(transitionID, symbol):
            state.transitionsDict[transitionID]?.symbols.removeAll(where: { $0 == symbol })
        case let .automataShapeClassified(.success(.state(stateStroke))):
            let center = shapeService.center(stateStroke.controlPoints)
            let radius = shapeService.radius(stateStroke.controlPoints, center)
            
            let controlPoints: [CGPoint] = shapeService.circle(
                center,
                radius
            )
            
            // Make a state final if this is a double circle
            if let automatonState = enclosingState(for: controlPoints) {
                guard !automatonState.isFinalState else {
                    state.shouldDeleteLastStroke = true
                    return .none
                }
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
                    id: idFactory.generateID(),
                    center: center,
                    radius: radius
                )
                
                transition.endState = automatonState.id
                state.transitionsDict[transition.id] = transition
                
                state.automatonStatesDict[automatonState.id] = automatonState
                registerUndo(.automatonStateRemoved(automatonState.id))
            // Connect to a transition without start state if one is close enough
            } else if var transition = closestTransitionWithoutStartState(for: controlPoints) {
                guard
                    let startPoint = transition.startPoint,
                    let tipPoint = transition.tipPoint
                else { return .none }
                let vector = Vector(tipPoint, startPoint)
                let center = vector.point(distance: radius, other: startPoint)
                
                let automatonState = AutomatonState(
                    id: idFactory.generateID(),
                    center: center,
                    radius: radius
                )
                
                transition.startState = automatonState.id
                state.transitionsDict[transition.id] = transition
                
                state.automatonStatesDict[automatonState.id] = automatonState
                registerUndo(.automatonStateRemoved(automatonState.id))
            } else {
                let automatonState = AutomatonState(
                    id: idFactory.generateID(),
                    center: center,
                    radius: radius
                )
                state.automatonStatesDict[automatonState.id] = automatonState
                registerUndo(.automatonStateRemoved(automatonState.id))
            }
        case let .transitionFlexPointFinishedDragging(transitionID, finalFlexPoint):
            guard var transition = state.transitionsDict[transitionID] else { return .none }
            /// Update `currentFlexPoint` only when dragging has finished
            transition.currentFlexPoint = finalFlexPoint
            updateDraggedTransition(transition, flexPoint: finalFlexPoint)
        case let .transitionFlexPointChanged(transitionID, flexPoint):
            guard let transition = state.transitionsDict[transitionID] else { return .none }
            updateDraggedTransition(transition, flexPoint: flexPoint)
        case let .stateDragPointChanged(automatonStateID, currentDragPoint):
            state.automatonStatesDict[automatonStateID]?.currentDragPoint = currentDragPoint
            updateTransitionsAfterStateDragged(automatonStateID)
        case let .stateDragPointFinishedDragging(automatonStateID, currentDragPoint):
            state.automatonStatesDict[automatonStateID]?.currentDragPoint = currentDragPoint
            state.automatonStatesDict[automatonStateID]?.dragPoint = currentDragPoint
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
                id: idFactory.generateID(),
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
                id: idFactory.generateID(),
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
            guard let stroke = strokes.last else { return .none }
            return .task {
                do {
                    let shape = try await automataClassifierService.recognizeStroke(stroke)
                    return Action.automataShapeClassified(.success(shape))
                } catch {
                    return Action.automataShapeClassified(.failure(.shapeNotRecognized))
                }
            }
        case .onAppear:
            return undoService.registerUndoManager()
        case .undo:
            undoService.undo()
        case .redo:
            undoService.redo()
        }
        
        return .none
    }
}
