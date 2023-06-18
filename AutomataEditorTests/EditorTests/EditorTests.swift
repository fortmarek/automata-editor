import XCTest
import ComposableArchitecture
@testable import AutomataEditor

@MainActor
final class EditorTests: XCTestCase {
    let scheduler = DispatchQueue.test
    var stubShapeType: AutomatonShapeType!
    var stubID: String!
    var stubCenter: CGPoint!
    var stubRadius: CGFloat!
    var automatonURL = URL(string: "file://some-file")!
    var store: TestStore<EditorFeature.State, EditorFeature.Action, EditorFeature.State, EditorFeature.Action, ()>!
    var clock: TestClock<Duration>!
    
    override func setUp() {
        super.setUp()
        
        store = TestStore(
            initialState: EditorFeature.State(automatonURL: automatonURL),
            reducer: EditorFeature()
        )
        store.dependencies.automataClassifierService = .successfulShape { self.stubShapeType }
        store.dependencies.automataLibraryService = .successful()
        store.dependencies.shapeService = .mock(
            center: { $0.first ?? .zero },
            radius: { _, _ in self.stubRadius }
        )
        store.dependencies.idFactory = .mock { self.stubID }
        store.dependencies.undoService = .live
        clock = TestClock()
        store.dependencies.continuousClock = clock
        store.send(.onAppear)
        stubShapeType = .circle
        stubID = "1"
        stubCenter = .zero
        stubRadius = 1
    }
    
    override func tearDown() {
        store = nil
        clock = nil
        stubShapeType = nil
        stubID = nil
        stubCenter = nil
        stubRadius = nil
        
        super.tearDown()
    }
    
    func testManualTransitionCreation() async {
        var currentStrokes: [Stroke] = []
        stubRadius = 5
        await store.send(.startAddingTransition) {
            $0.mode = .addingTransition
        }
        self.stubID = "A"
        await createState(
            store: store,
            id: "A",
            center: CGPoint(x: 5, y: 5),
            radius: 5,
            currentStrokes: &currentStrokes
        )
        self.stubID = "B"
        
        await createState(
            store: store,
            id: "B",
            center: CGPoint(x: 20, y: 5),
            radius: 5,
            currentStrokes: &currentStrokes
        )
        
        await store.send(.selectedStateForTransition("A")) {
            $0.currentlySelectedStateForTransition = "A"
        }
        await store.send(.selectedStateForTransition("A")) {
            $0.currentlySelectedStateForTransition = nil
        }
        await store.send(.selectedStateForTransition("A")) {
            $0.currentlySelectedStateForTransition = "A"
        }
        self.stubID = "T"
        await store.send(.selectedStateForTransition("B")) {
            $0.transitionsDict["T"] = AutomatonTransition(
                id: "T",
                startState: "A",
                endState: "B",
                type: .regular(
                    startPoint: CGPoint(x: 10, y: 5),
                    tipPoint: CGPoint(x: 15, y: 5),
                    flexPoint: CGPoint(x: 12.5, y: 5)
                ),
                currentFlexPoint: CGPoint(x: 12.5, y: 5)
            )
            $0.currentlySelectedStateForTransition = nil
            $0.mode = .editing
        }
    }
    
    func testTransitionSymbolIsTrimmedAndUppercased() async {
        var currentStrokes: [Stroke] = []
        store.dependencies.automataClassifierService = .successfulShape { .arrow }
        store.dependencies.automataLibraryService = .successful()
        store.dependencies.shapeService = .mock(
            center: { $0.first ?? .zero },
            radius: { _, _ in 1 }
        )
        store.dependencies.idFactory = .mock { self.stubID }

        await createTransition(
            store: store,
            startPoint: .zero,
            tipPoint: CGPoint(x: 1, y: 0),
            transitionID: stubID,
            currentStrokes: &currentStrokes
        )
        await store.send(.transitionSymbolChanged(stubID, "a \n")) { [self] in
            $0.transitionsDict[stubID]?.currentSymbol = "a"
        }
    }

    func testSimulateWithoutInitialState() async {
        var currentStrokes: [Stroke] = []
        store.dependencies.mainQueue = scheduler.eraseToAnyScheduler()
        await createState(
            store: store,
            id: stubID,
            center: stubCenter,
            radius: stubRadius,
            currentStrokes: &currentStrokes
        )

        await store.send(.stateSymbolChanged("1", "A")) {
            $0.automatonStatesDict["1"]?.name = "A"
        }

        await createEndStateStroke(
            store: store,
            stateID: "1",
            controlPoints: [.zero],
            currentStrokes: &currentStrokes
        )

        await store.send(.inputChanged("A")) {
            $0.input = "A"
        }
        await store.send(.simulateInput) {
            $0.automatonOutput = .failure("No initial state")
            $0.isAutomatonOutputVisible = true
        }
        await clock.advance(by: .seconds(5))
        await store.receive(.dismissToast) {
            $0.isAutomatonOutputVisible = false
        }
    }

    func testSimulateWithMultipleInitialStates() async {
        var currentStrokes: [Stroke] = []
        store.dependencies.idFactory = .mock { self.stubID }

        await createState(
            store: store,
            id: stubID,
            center: stubCenter,
            radius: stubRadius,
            currentStrokes: &currentStrokes
        )

        await store.send(.stateSymbolChanged("1", "A")) {
            $0.automatonStatesDict["1"]?.name = "A"
        }

        await createEndStateStroke(
            store: store,
            stateID: "1",
            controlPoints: [.zero],
            currentStrokes: &currentStrokes
        )

        stubID = "2"
        await createState(
            store: store,
            id: stubID,
            center: CGPoint(x: 10, y: 0),
            radius: stubRadius,
            currentStrokes: &currentStrokes
        )
        await store.send(.stateSymbolChanged("2", "B")) {
            $0.automatonStatesDict["2"]?.name = "B"
        }

        stubShapeType = .arrow

        stubID = "1"
        await createTransition(
            store: store,
            startPoint: CGPoint(x: -2, y: 0),
            tipPoint: CGPoint(x: 0, y: 0),
            transitionID: stubID,
            endStateID: "1",
            currentStrokes: &currentStrokes
        )

        stubID = "2"
        await createTransition(
            store: store,
            startPoint: CGPoint(x: 8, y: 0),
            tipPoint: CGPoint(x: 10, y: 0),
            transitionID: stubID,
            endStateID: "2",
            currentStrokes: &currentStrokes
        )

        await store.send(.simulateInput) {
            $0.automatonOutput = .failure("Multiple initial states")
            $0.isAutomatonOutputVisible = true
        }
        await clock.advance(by: .seconds(5))
        await store.receive(.dismissToast) {
            $0.isAutomatonOutputVisible = false
        }
    }

    func testSimpleAutomatonIsDrawnAndSimulated() async {
        var currentStrokes: [Stroke] = []
        await createState(
            store: store,
            id: stubID,
            center: stubCenter,
            radius: stubRadius,
            currentStrokes: &currentStrokes
        )

        await store.send(.stateSymbolChanged("1", "A")) {
            $0.automatonStatesDict["1"]?.name = "A"
        }

        stubShapeType = .arrow

        stubID = "2"
        await createTransition(
            store: store,
            startPoint: .zero,
            tipPoint: CGPoint(x: 2, y: 0),
            transitionID: stubID,
            startStateID: "1",
            currentStrokes: &currentStrokes
        )

        await store.send(.transitionSymbolChanged("2", "A")) {
            $0.transitionsDict["2"]?.currentSymbol = "A"
        }

        stubShapeType = .circle
        stubID = "3"

        await createState(
            store: store,
            id: "3",
            center: CGPoint(x: 3, y: 0),
            radius: 1,
            transitionEndID: "2",
            currentStrokes: &currentStrokes
        )
        await store.send(.stateSymbolChanged("3", "3")) {
            $0.automatonStatesDict["3"]?.name = "3"
        }

        currentStrokes.append(
            Stroke(
                controlPoints: [CGPoint(x: 3, y: 0)]
            )
        )
        await store.send(
            .strokesChanged(
                currentStrokes
            )
        )

        await store.receive(
            .automataShapeClassified(
                .success(
                    .state(
                        Stroke(
                            controlPoints: [CGPoint(x: 3, y: 0)]
                        )
                    )
                )
            )
        ) {
            $0.automatonStatesDict["3"]?.isFinalState = true
        }

        stubShapeType = .arrow
        stubID = "4"
        await createTransition(
            store: store,
            startPoint: CGPoint(x: -2, y: 0),
            tipPoint: .zero,
            transitionID: stubID,
            endStateID: "1",
            currentStrokes: &currentStrokes
        )

        await store.send(.inputChanged("A")) {
            $0.input = "A"
        }
        await store.send(.simulateInput)
        await store.receive(.simulateInputResult(.success(Empty()))) {
            $0.automatonOutput = .success
            $0.isAutomatonOutputVisible = true
        }
        await clock.advance(by: .seconds(5))
        await store.receive(.dismissToast) {
            $0.isAutomatonOutputVisible = false
        }
    }
    
    func testUndoAndRedo() async {
        
    }

    private func createEndStateStroke(
        store: TestStore<EditorFeature.State, EditorFeature.Action, EditorFeature.State, EditorFeature.Action, ()>,
        stateID: AutomatonState.ID,
        controlPoints: [CGPoint],
        currentStrokes: inout [Stroke]
    ) async {
        currentStrokes.append(
            Stroke(
                controlPoints: controlPoints
            )
        )
        await store.send(
            .strokesChanged(
                currentStrokes
            )
        )

        await store.receive(
            .automataShapeClassified(
                .success(
                    .state(
                        Stroke(
                            controlPoints: controlPoints
                        )
                    )
                )
            )
        ) {
            $0.automatonStatesDict[stateID]?.isFinalState = true
        }
    }

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
            
            $0.canUndo = true
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
        currentStrokes: inout [Stroke]
    ) async {
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
    }
}
