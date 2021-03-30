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
        var stubCenter: CGPoint = .zero
        var stubRadius: CGFloat = 1
        let store = TestStore(
            initialState: EditorState(),
            reducer: editorReducer,
            environment: EditorEnvironment(
                automataClassifierService: .successfulShape { stubShapeType },
                automataLibraryService: .successful(),
                shapeService: .mock(
                    center: { _ in stubCenter },
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
            radius: stubRadius
        )
        
        store.send(.stateSymbolChanged("1", "A")) {
            $0.automatonStatesDict["1"]?.name = "A"
        }
        
        stubShapeType = .arrow
        
        
    }
//        .assert(
//            createState(center: .zero) +
//                [
//                    .send(
//                        .stateSymbolChanged(
//                            Stroke(
//                                controlPoints: .circle(
//                                    center: .zero,
//                                    radius: 1
//                                )
//                            ),
//                            "A"
//                        )
//                    ) {
//                        $0.automatonStates[0].name = "A"
//                    },
//                    .do {
//                        stubShapeType = .arrow
//                    }
//                ]
//                + createTransition(
//                    startAutomatonIndex: 0
//                )
//                + [
//                    .send(
//                        .transitionSymbolChanged(
//                            AutomatonTransition(
//                                startState: nil,
//                                endState: nil,
//                                scribblePosition: CGPoint(
//                                    x: 2,
//                                    y: -50
//                                ),
//                                stroke: Stroke(
//                                    controlPoints: .arrow(
//                                        startPoint: CGPoint(x: 1, y: 0),
//                                        tipPoint: CGPoint(x: 3, y: 0)
//                                    )
//                                )
//                            ),
//                            "A"
//                        )
//                    ) {
//                        $0.transitions[0].currentSymbol = "A"
//                    },
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
        radius: CGFloat
    ) {
        store.send(
            .strokesChanged(
                [
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
            $0.automatonStatesDict = [
                id: AutomatonState(
                    id: id,
                    center: center,
                    radius: radius
                ),
            ]
        }
    }
//            .receive(
//                .automataShapeClassified(
//                    .success(
//                        .state(
//                            Stroke(
//                                controlPoints: .circle
//                            )
//                        )
//                    )
//                )
//            ) {
//                $0.automatonStates = [
//                    AutomatonState(
//                        scribblePosition: CGPoint(x: 0, y: 0),
//                        stroke: Stroke(
//                            controlPoints: .circle(
//                                center: CGPoint(x: 0, y: 0),
//                                radius: 1
//                            )
//                        )
//                    ),
//                ]
//            },
//        ]
//    }
    
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
