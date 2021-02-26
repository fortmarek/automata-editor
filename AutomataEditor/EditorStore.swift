import ComposableArchitecture
import CoreGraphics
import PencilKit

typealias EditorStore = Store<EditorState, EditorAction>
typealias EditorViewStore = ViewStore<EditorState, EditorAction>

struct EditorEnvironment {}

struct Stroke: Equatable {
    let controlPoints: [CGPoint]
    
    init(
        controlPoints: [CGPoint]
    ) {
        self.controlPoints = controlPoints
    }
    
    init(_ stroke: PKStroke) {
        controlPoints = stroke.path
            .interpolatedPoints(by: .distance(50))
            .map(\.location)
    }
    
    func pkStroke() -> PKStroke {
        PKStroke(
            ink: PKInk(.pen),
            path: PKStrokePath(
                controlPoints: controlPoints.map(strokePoint),
                creationDate: Date()
            )
        )
    }
    
    private func strokePoint(
        _ location: CGPoint
    ) -> PKStrokePoint {
        PKStrokePoint(
            location: location,
            timeOffset: 0,
            size: CGSize(width: 4, height: 4),
            opacity: 1,
            force: 1,
            azimuth: 0,
            altitude: 0
        )
    }
}

struct EditorState: Equatable {
    var strokes: [Stroke] = []
}

enum EditorAction: Equatable {
    case strokesChanged([Stroke])
}

let editorReducer = Reducer<EditorState, EditorAction, EditorEnvironment> { state, action, env in
    switch action {
    case let .strokesChanged(strokes):
        guard let stroke = strokes.last else { return .none }
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

        state.strokes.append(
            Stroke(controlPoints: controlPoints)
        )
    }
    
    return .none
}
