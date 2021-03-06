import XCTest
import ComposableArchitecture
@testable import AutomataEditor

final class EditorTests: XCTestCase {
    let scheduler = DispatchQueue.testScheduler
    
    func testSimpleAutomatonIsDrawn() {
        var stubShapeType: AutomatonShapeType = .circle
            TestStore(
                initialState: EditorState(),
                reducer: editorReducer,
                environment: EditorEnvironment(
                    automataClassifierService: .successfulShape { stubShapeType },
                    mainQueue: scheduler.eraseToAnyScheduler()
                )
            )
            .assert(
                createState(center: .zero) +
                    [
                        .send(
                            .stateSymbolChanged(
                                AutomatonState(
                                    scribblePosition: .zero,
                                    stroke: Stroke(
                                        controlPoints: .circle(
                                            center: .zero,
                                            radius: 1
                                        )
                                    )
                                ),
                                "A"
                            )
                        ) {
                            $0.automatonStates[0].symbol = "A"
                        },
                        .do {
                            stubShapeType = .arrow
                        },
                        .send(
                            .strokesChanged(
                                [
                                    Stroke(
                                        controlPoints: [
                                            CGPoint(x: 2, y: 0),
                                            CGPoint(x: 3, y: 0),
                                        ]
                                    )
                                ]
                            )
                        ),
                        .do {
                            self.scheduler.advance()
                        },
                        .receive(
                            .automataShapeClassified(
                                .success(
                                    .transition(
                                        Stroke(
                                            controlPoints: [
                                                CGPoint(x: 2, y: 0),
                                                CGPoint(x: 3, y: 0),
                                            ]
                                        )
                                    )
                                )
                            )
                        ) {
                            $0.transitions = [
                                AutomatonTransition(
                                    startState: $0.automatonStates[0],
                                    endState: nil,
                                    scribblePosition: CGPoint(
                                        x: 2,
                                        y: -50
                                    ),
                                    stroke: Stroke(
                                        controlPoints: .arrow(
                                            startPoint: CGPoint(x: 1, y: 0),
                                            tipPoint: CGPoint(x: 3, y: 0)
                                        )
                                    )
                                )
                            ]
                        },
                        .send(
                            .transitionSymbolChanged(
                                AutomatonTransition(
                                    startState: nil,
                                    endState: nil,
                                    scribblePosition: CGPoint(
                                        x: 2,
                                        y: -50
                                    ),
                                    stroke: Stroke(
                                        controlPoints: .arrow(
                                            startPoint: CGPoint(x: 1, y: 0),
                                            tipPoint: CGPoint(x: 3, y: 0)
                                        )
                                    )
                                ),
                                "A"
                            )
                        ) {
                            $0.transitions[0].symbol = "A"
                        },
                        .do {
                            stubShapeType = .circle
                        },
                        .send(
                            .strokesChanged(
                                [
                                    Stroke(
                                        controlPoints: [
                                            CGPoint(x: 0, y: -2),
                                            CGPoint(x: 2, y: 0),
                                            CGPoint(x: 0, y: 2),
                                            CGPoint(x: -2, y: 0),
                                        ]
                                    )
                                ]
                            )
                        ),
                        .do { self.scheduler.advance() },
                        .receive(
                            .automataShapeClassified(
                                .success(
                                    .state(
                                        Stroke(
                                            controlPoints: [
                                                CGPoint(x: 0, y: -2),
                                                CGPoint(x: 2, y: 0),
                                                CGPoint(x: 0, y: 2),
                                                CGPoint(x: -2, y: 0),
                                            ]
                                        )
                                    )
                                )
                            )
                        ) {
                            let center = $0.automatonStates[0].stroke.controlPoints.center()
                            $0.automatonStates[0].endStroke = Stroke(
                                controlPoints: .circle(
                                    center: center,
                                    radius: $0.automatonStates[0].stroke.controlPoints.radius(with: center) * 0.7
                                )
                            )
                        }
                    ]
            )
    }
    
    private func createState(
        center: CGPoint
    ) -> [TestStore<EditorState, EditorState, EditorAction, EditorAction, EditorEnvironment>.Step] {
        [
            .send(
                .strokesChanged(
                    [
                        Stroke(
                            controlPoints: .circle
                        )
                    ]
                )
            ),
            .do { self.scheduler.advance() },
            .receive(
                .automataShapeClassified(
                    .success(
                        .state(
                            Stroke(
                                controlPoints: .circle
                            )
                        )
                    )
                )
            ) {
                $0.automatonStates = [
                    AutomatonState(
                        scribblePosition: CGPoint(x: 0, y: 0),
                        stroke: Stroke(
                            controlPoints: .circle(
                                center: CGPoint(x: 0, y: 0),
                                radius: 1
                            )
                        )
                    ),
                ]
            },
        ]
    }
}

extension Array where Element == CGPoint {
    static let circle: Self = [
        CGPoint(x: 0, y: -1),
        CGPoint(x: 1, y: 0),
        CGPoint(x: 0, y: 1),
        CGPoint(x: -1, y: 0),
    ]
}
