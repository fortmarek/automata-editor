import Foundation
import CoreML
import UIKit
import PencilKit
import ComposableArchitecture
import Combine

enum AutomatonShapeType: String {
    case circle
    case arrow
    case cycle
}

extension AutomataClassifierService {
    static let live = Self(
        recognizeStroke: { stroke in
            guard
                let image = PKDrawing(strokes: [stroke.pkStroke()])
                .image(
                    from: stroke.pkStroke().renderBounds,
                    scale: 1.0
                )
                .modelImage(),
                let cgImage = image.cgImage
            else {
                throw AutomataClassifierError.shapeNotRecognized
            }

            let input = try AutomataClassifierInput(drawingWith: cgImage)
            let classifier = try AutomataClassifier(configuration: MLModelConfiguration())
            let prediction = try classifier.prediction(input: input)

            guard
                let automataShapeType = AutomatonShapeType(rawValue: prediction.label)
            else { throw AutomataClassifierError.shapeNotRecognized }

            switch automataShapeType {
            case .arrow:
                return .transition(stroke)
            case .circle:
                return .state(stroke)
            case .cycle:
                return .transitionCycle(stroke)
            }
        }
    )
}
