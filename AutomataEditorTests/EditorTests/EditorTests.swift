import XCTest
import ComposableArchitecture
@testable import AutomataEditor

@MainActor
final class EditorTests: XCTestCase {
    let scheduler = DispatchQueue.test
    var currentStrokes: [Stroke] = []
    var stubShapeType: AutomatonShapeType!
    var stubID: String!
    var stubCenter: CGPoint!
    var stubRadius: CGFloat!
    
    override func setUp() {
        super.setUp()
        
        stubShapeType = .circle
        stubID = "1"
        stubCenter = .zero
        stubRadius = 1
    }
    
    override func tearDown() {
        currentStrokes = []
        stubShapeType = nil
        stubID = nil
        stubCenter = nil
        stubRadius = nil
        
        super.tearDown()
    }
    
    func testTransitionSymbolIsTrimmedAndUppercased() async {
        let store = TestStore(
            initialState: EditorFeature.State(),
            reducer: EditorFeature()
        )
        store.dependencies.automataClassifierService = .successfulShape { .arrow }
        store.dependencies.automataLibraryService = .successful()
        store.dependencies.shapeService = .mock(
            center: { $0.first ?? .zero },
            radius: { _, _ in 1 }
        )
        store.dependencies.idFactory = .mock { self.stubID }

        currentStrokes = await createTransition(
            store: store,
            startPoint: .zero,
            tipPoint: CGPoint(x: 1, y: 0),
            transitionID: stubID,
            currentStrokes: currentStrokes
        )
        await store.send(.transitionSymbolChanged(stubID, "a \n")) { [self] in
            $0.transitionsDict[stubID]?.currentSymbol = "A"
        }
    }
//
//    func testSimulateWithoutInitialState() {
//        var currentStrokes: [Stroke] = []
//        let store = TestStore(
//            initialState: EditorState(),
//            reducer: editorReducer,
//            environment: EditorEnvironment(
//                automataClassifierService: .successfulShape { self.stubShapeType },
//                automataLibraryService: .successful(),
//                shapeService: .mock(
//                    center: { $0.first ?? .zero },
//                    radius: { _, _ in self.stubRadius }
//                ),
//                idFactory: .mock { self.stubID },
//                mainQueue: scheduler.eraseToAnyScheduler()
//            )
//        )
//        createState(
//            store: store,
//            id: stubID,
//            center: stubCenter,
//            radius: stubRadius,
//            currentStrokes: &currentStrokes
//        )
//
//        store.send(.stateSymbolChanged("1", "A")) {
//            $0.automatonStatesDict["1"]?.name = "A"
//        }
//
//        createEndStateStroke(
//            store: store,
//            stateID: "1",
//            controlPoints: [.zero],
//            currentStrokes: &currentStrokes
//        )
//
//        store.send(.inputChanged("A")) {
//            $0.input = "A"
//        }
//        store.send(.simulateInput) {
//            $0.outputString = "❌ No initial state"
//        }
//    }
//
//    func testSimulateWithMultipleInitialStates() {
//        let store = TestStore(
//            initialState: EditorState(),
//            reducer: editorReducer,
//            environment: EditorEnvironment(
//                automataClassifierService: .successfulShape { self.stubShapeType },
//                automataLibraryService: .successful(),
//                shapeService: .mock(
//                    center: { $0.first ?? .zero },
//                    radius: { _, _ in self.stubRadius }
//                ),
//                idFactory: .mock { self.stubID },
//                mainQueue: scheduler.eraseToAnyScheduler()
//            )
//        )
//        createState(
//            store: store,
//            id: stubID,
//            center: stubCenter,
//            radius: stubRadius,
//            currentStrokes: &currentStrokes
//        )
//
//        store.send(.stateSymbolChanged("1", "A")) {
//            $0.automatonStatesDict["1"]?.name = "A"
//        }
//
//        createEndStateStroke(
//            store: store,
//            stateID: "1",
//            controlPoints: [.zero],
//            currentStrokes: &currentStrokes
//        )
//
//        stubID = "2"
//        createState(
//            store: store,
//            id: stubID,
//            center: CGPoint(x: 10, y: 0),
//            radius: stubRadius,
//            currentStrokes: &currentStrokes
//        )
//        store.send(.stateSymbolChanged("2", "B")) {
//            $0.automatonStatesDict["2"]?.name = "B"
//        }
//
//        stubShapeType = .arrow
//
//        stubID = "1"
//        createTransition(
//            store: store,
//            startPoint: CGPoint(x: -2, y: 0),
//            tipPoint: CGPoint(x: 0, y: 0),
//            transitionID: stubID,
//            endStateID: "1",
//            currentStrokes: &currentStrokes
//        )
//
//        stubID = "2"
//        createTransition(
//            store: store,
//            startPoint: CGPoint(x: 8, y: 0),
//            tipPoint: CGPoint(x: 10, y: 0),
//            transitionID: stubID,
//            endStateID: "2",
//            currentStrokes: &currentStrokes
//        )
//
//        store.send(.simulateInput) {
//            $0.outputString = "❌ Multiple initial states"
//        }
//    }
//
//    func testSimpleAutomatonIsDrawnAndSimulated() {
//        let store = TestStore(
//            initialState: EditorState(),
//            reducer: editorReducer,
//            environment: EditorEnvironment(
//                automataClassifierService: .successfulShape { self.stubShapeType },
//                automataLibraryService: .successful(),
//                shapeService: .mock(
//                    center: { $0.first ?? .zero },
//                    radius: { _, _ in self.stubRadius }
//                ),
//                idFactory: .mock { self.stubID },
//                mainQueue: scheduler.eraseToAnyScheduler()
//            )
//        )
//        createState(
//            store: store,
//            id: stubID,
//            center: stubCenter,
//            radius: stubRadius,
//            currentStrokes: &currentStrokes
//        )
//
//        store.send(.stateSymbolChanged("1", "A")) {
//            $0.automatonStatesDict["1"]?.name = "A"
//        }
//
//        stubShapeType = .arrow
//
//        stubID = "2"
//        createTransition(
//            store: store,
//            startPoint: .zero,
//            tipPoint: CGPoint(x: 2, y: 0),
//            transitionID: stubID,
//            startStateID: "1",
//            currentStrokes: &currentStrokes
//        )
//
//        store.send(.transitionSymbolChanged("2", "A")) {
//            $0.transitionsDict["2"]?.currentSymbol = "A"
//        }
//
//        stubShapeType = .circle
//        stubID = "3"
//
//        createState(
//            store: store,
//            id: "3",
//            center: CGPoint(x: 3, y: 0),
//            radius: 1,
//            transitionEndID: "2",
//            currentStrokes: &currentStrokes
//        )
//        store.send(.stateSymbolChanged("3", "3")) {
//            $0.automatonStatesDict["3"]?.name = "3"
//        }
//
//        currentStrokes.append(
//            Stroke(
//                controlPoints: [CGPoint(x: 3, y: 0)]
//            )
//        )
//        store.send(
//            .strokesChanged(
//                currentStrokes
//            )
//        )
//
//        scheduler.advance()
//
//        store.receive(
//            .automataShapeClassified(
//                .success(
//                    .state(
//                        Stroke(
//                            controlPoints: [CGPoint(x: 3, y: 0)]
//                        )
//                    )
//                )
//            )
//        ) {
//            $0.automatonStatesDict["3"]?.isFinalState = true
//        }
//
//        stubShapeType = .arrow
//        stubID = "4"
//        createTransition(
//            store: store,
//            startPoint: CGPoint(x: -2, y: 0),
//            tipPoint: .zero,
//            transitionID: stubID,
//            endStateID: "1",
//            currentStrokes: &currentStrokes
//        )
//
//        store.send(.inputChanged("A")) {
//            $0.input = "A"
//        }
//        store.send(.simulateInput)
//        scheduler.advance()
//        store.receive(.simulateInputResult(.success(Empty()))) {
//            $0.outputString = "✅"
//        }
//    }
//
//    private func createEndStateStroke(
//        store: TestStore<EditorState, EditorState, EditorAction, EditorAction, EditorEnvironment>,
//        stateID: AutomatonState.ID,
//        controlPoints: [CGPoint],
//        currentStrokes: inout [Stroke]
//    ) {
//        currentStrokes.append(
//            Stroke(
//                controlPoints: controlPoints
//            )
//        )
//        store.send(
//            .strokesChanged(
//                currentStrokes
//            )
//        )
//
//        scheduler.advance()
//
//        store.receive(
//            .automataShapeClassified(
//                .success(
//                    .state(
//                        Stroke(
//                            controlPoints: controlPoints
//                        )
//                    )
//                )
//            )
//        ) {
//            $0.automatonStatesDict[stateID]?.isFinalState = true
//        }
//    }

    private func createState(
        store: TestStore<EditorFeature.State, EditorFeature.Action, EditorFeature.State, EditorFeature.Action, ()>,
        id: String,
        center: CGPoint,
        radius: CGFloat,
        transitionEndID: AutomatonTransition.ID? = nil,
        currentStrokes: inout [Stroke]
    ) async {
        await store.send(
            .strokesChanged(
                currentStrokes + [
                    Stroke(controlPoints: [center])
                ]
            )
        )
        await scheduler.advance()

        await store.receive(
            .automataShapeClassified(
                .success(
                    .state(
                        Stroke(
                            controlPoints: [center]
                        )
                    )
                )
            )
        ) {
            $0.automatonStatesDict[id] = AutomatonState(
                id: id,
                center: center,
                radius: radius
            )

            if let transitionEndID = transitionEndID {
                $0.transitionsDict[transitionEndID]?.endState = id
            }
        }

        currentStrokes.append(
            Stroke(
                controlPoints: [center]
            )
        )
    }


    private func createTransition(
        store: TestStore<EditorFeature.State, EditorFeature.Action, EditorFeature.State, EditorFeature.Action, ()>,
        startPoint: CGPoint,
        tipPoint: CGPoint,
        transitionID: String,
        startStateID: AutomatonState.ID? = nil,
        endStateID: AutomatonState.ID? = nil,
        currentStrokes: [Stroke]
    ) async -> [Stroke] {
        var currentStrokes = currentStrokes
        let stroke = Stroke(
            controlPoints: [
                startPoint,
                tipPoint,
            ]
        )
        await store.send(
            .strokesChanged(
                currentStrokes + [
                    stroke,
                ]
            )
        )

        await scheduler.advance()

        await store.receive(
            .automataShapeClassified(
                .success(
                    .transition(stroke)
                )
            )
        ) {
            $0.transitionsDict[transitionID] = AutomatonTransition(
                id: transitionID,
                startState: startStateID,
                endState: endStateID,
                type: .regular(
                    startPoint: startPoint,
                    tipPoint: tipPoint,
                    flexPoint: CGPoint(
                        x: (startPoint.x + tipPoint.x) / 2,
                        y: (startPoint.y + tipPoint.y) / 2
                    )
                ),
                currentFlexPoint: CGPoint(
                    x: (startPoint.x + tipPoint.x) / 2,
                    y: (startPoint.y + tipPoint.y) / 2
                )
            )
        }

        currentStrokes.append(
            Stroke(
                controlPoints: [startPoint, tipPoint]
            )
        )
        
        return currentStrokes
    }
}
