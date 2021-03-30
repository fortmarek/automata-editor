import XCTest
import ComposableArchitecture
@testable import AutomataEditor

final class EditorTests: XCTestCase {
    let scheduler = DispatchQueue.testScheduler
    
//    func testEraseAutomatonAndTransition() {
//        var stubShapeType: AutomatonShapeType = .circle
//        var stubID: String = "1"
//        let store = TestStore(
//            initialState: EditorState(),
//            reducer: editorReducer,
//            environment: EditorEnvironment(
//                automataClassifierService: .successfulShape { stubShapeType },
//                automataLibraryService: .successful(),
//                idFactory: .mock { stubID },
//                mainQueue: scheduler.eraseToAnyScheduler()
//            )
//        )
//
//        createState(store: store, center: .zero, radius: 2)
//        .assert(
//            createState(center: .zero)
//                + [
//                    .do { stubShapeType = .arrow }
//                ]
//                + createTransition(
//                    startAutomatonIndex: 0
//                )
//                + [
//                    // the computation of center is not good enough
//                    .send(
//                        // Automaton state is missing signalling it has been erased
//                        .strokesChanged(
//                            [
//                                Stroke(
//                                    controlPoints: .arrow(
//                                        startPoint: CGPoint(x: 1, y: 0),
//                                        tipPoint: CGPoint(x: 3, y: 0)
//                                    )
//                                )
//                            ]
//                        )
//                    ) {
//                        $0.automatonStates = []
//                        $0.transitions[0].startState = nil
//                    },
//                    .send(
//                        // Automaton state is missing signalling it has been erased
//                        .strokesChanged([])
//                    ) {
//                        $0.automatonStates = []
//                        $0.transitions = []
//                    },
//                ]
//        )
//    }
    
    func testSimpleAutomatonIsDrawn() {
        var stubShapeType: AutomatonShapeType = .circle
        var stubID: String = "1"
        let stubCenter: CGPoint = .zero
        let stubRadius: CGFloat = 1
        var currentStrokes: [Stroke] = []
        let store = TestStore(
            initialState: EditorState(),
            reducer: editorReducer,
            environment: EditorEnvironment(
                automataClassifierService: .successfulShape { stubShapeType },
                automataLibraryService: .successful(),
                shapeService: .mock(
                    center: { $0.first ?? .zero },
                    radius: { _, _ in stubRadius }
                ),
                idFactory: .mock { stubID },
                mainQueue: scheduler.eraseToAnyScheduler()
            )
        )
        createState(
            store: store,
            id: stubID,
            center: stubCenter,
            radius: stubRadius,
            currentStrokes: &currentStrokes
        )
        
        store.send(.stateSymbolChanged("1", "A")) {
            $0.automatonStatesDict["1"]?.name = "A"
        }
        
        stubShapeType = .arrow
        
        stubID = "2"
        createTransition(
            store: store,
            startPoint: .zero,
            tipPoint: CGPoint(x: 2, y: 0),
            transitionID: stubID,
            startStateID: "1",
            currentStrokes: &currentStrokes
        )
        
        store.send(.transitionSymbolChanged("2", "A")) {
            $0.transitionsDict["2"]?.currentSymbol = "A"
        }
        
        stubShapeType = .circle
        stubID = "3"
        
        createState(
            store: store,
            id: "3",
            center: CGPoint(x: 3, y: 0),
            radius: 1,
            transitionEndID: "2",
            currentStrokes: &currentStrokes
        )
    }
//                    .do {
//                        stubShapeType = .circle
//                    },
//                    .send(
//                        .strokesChanged(
//                            [
//                                Stroke(
//                                    controlPoints: .circle(
//                                        center: .zero,
//                                        radius: 1
//                                    )
//                                ),
//                                Stroke(
//                                    controlPoints: [
//                                        CGPoint(x: 0, y: -2),
//                                        CGPoint(x: 2, y: 0),
//                                        CGPoint(x: 0, y: 2),
//                                        CGPoint(x: -2, y: 0),
//                                    ]
//                                )
//                            ]
//                        )
//                    ),
//                    .do { self.scheduler.advance() },
//                    .receive(
//                        .automataShapeClassified(
//                            .success(
//                                .state(
//                                    Stroke(
//                                        controlPoints: [
//                                            CGPoint(x: 0, y: -2),
//                                            CGPoint(x: 2, y: 0),
//                                            CGPoint(x: 0, y: 2),
//                                            CGPoint(x: -2, y: 0),
//                                        ]
//                                    )
//                                )
//                            )
//                        )
//                    ) {
//                        let center = $0.automatonStates[0].stroke.controlPoints.center()
//                        $0.automatonStates[0].endStroke = Stroke(
//                            controlPoints: .circle(
//                                center: center,
//                                radius: $0.automatonStates[0].stroke.controlPoints.radius(with: center) * 0.7
//                            )
//                        )
//                    }
//                ]
//        )
//    }
    
    private func createState(
        store: TestStore<EditorState, EditorState, EditorAction, EditorAction, EditorEnvironment>,
        id: String,
        center: CGPoint,
        radius: CGFloat,
        transitionEndID: AutomatonTransition.ID? = nil,
        currentStrokes: inout [Stroke]
    ) {
        store.send(
            .strokesChanged(
                currentStrokes + [
                    Stroke(controlPoints: [center])
                ]
            )
        )
        scheduler.advance()
        
        store.receive(
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
        store: TestStore<EditorState, EditorState, EditorAction, EditorAction, EditorEnvironment>,
        startPoint: CGPoint,
        tipPoint: CGPoint,
        transitionID: String,
        startStateID: AutomatonState.ID? = nil,
        endStateID: AutomatonState.ID? = nil,
        currentStrokes: inout [Stroke]
    ) {
        let stroke = Stroke(
            controlPoints: [
                startPoint,
                tipPoint,
            ]
        )
        store.send(
            .strokesChanged(
                currentStrokes + [
                    stroke,
                ]
            )
        )
        
        scheduler.advance()
        
        store.receive(
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
//    private func createTransition(
//        startAutomatonIndex: Int? = nil,
//        endAutomatonIndex: Int? = nil
//    ) -> [TestStore<EditorState, EditorState, EditorAction, EditorAction, EditorEnvironment>.Step] {
//        [
//            .send(
//                .strokesChanged(
//                    [
//                        Stroke(
//                            controlPoints: [
//                                CGPoint(x: 2, y: 0),
//                                CGPoint(x: 3, y: 0),
//                            ]
//                        )
//                    ]
//                )
//            ),
//            .do {
//                self.scheduler.advance()
//            },
//            .receive(
//                .automataShapeClassified(
//                    .success(
//                        .transition(
//                            Stroke(
//                                controlPoints: [
//                                    CGPoint(x: 2, y: 0),
//                                    CGPoint(x: 3, y: 0),
//                                ]
//                            )
//                        )
//                    )
//                )
//            ) { state in
//                state.transitions = [
//                    AutomatonTransition(
//                        startState: startAutomatonIndex.map { state.automatonStates[$0].id },
//                        endState: endAutomatonIndex.map { state.automatonStates[$0].id },
//                        scribblePosition: CGPoint(
//                            x: 2,
//                            y: -50
//                        ),
//                        stroke: Stroke(
//                            controlPoints: .arrow(
//                                startPoint: CGPoint(x: 1, y: 0),
//                                tipPoint: CGPoint(x: 3, y: 0)
//                            )
//                        )
//                    )
//                ]
//            }
//        ]
//    }
}

extension Array where Element == CGPoint {
    static let circle: Self = [
        CGPoint(x: 0, y: -1),
        CGPoint(x: 1, y: 0),
        CGPoint(x: 0, y: 1),
        CGPoint(x: -1, y: 0),
    ]
}
