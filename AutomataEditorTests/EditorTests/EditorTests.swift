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
                    )
                ]
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
                    Transition(
                        startState: AutomatonState(
                            scribblePosition: CGPoint(x: 0, y: 0),
                            stroke: Stroke(
                                controlPoints: .circle(
                                    center: CGPoint(x: 0, y: 0),
                                    radius: 1
                                )
                            )
                        ),
                        endState: nil,
                        stroke: Stroke(
                            controlPoints: .arrow(
                                startPoint: CGPoint(x: 1, y: 0),
                                tipPoint: CGPoint(x: 3, y: 0)
                            )
                        )
                    )
                ]
            }
        )
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
