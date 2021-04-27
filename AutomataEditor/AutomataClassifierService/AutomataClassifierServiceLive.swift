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
    static func live() -> Self {
        Self(
            recognizeStroke: { stroke in
                Future<AutomatonShape, AutomataClassifierError> { promise in
                    do {
                        guard
                            let image = PKDrawing(strokes: [stroke.pkStroke()])
                            .image(
                                from: stroke.pkStroke().renderBounds,
                                scale: 1.0
                            )
                            .modelImage(),
                            let cgImage = image.cgImage
                        else {
                            return promise(.failure(.shapeNotRecognized))
                        }

                        let input = try AutomataClassifierInput(drawingWith: cgImage)
                        let classifier = try AutomataClassifier(configuration: MLModelConfiguration())
                        let prediction = try classifier.prediction(input: input)

                        guard
                            let automataShapeType = AutomatonShapeType(rawValue: prediction.label)
                        else { return promise(.failure(.shapeNotRecognized)) }

                        switch automataShapeType {
                        case .arrow:
                            promise(.success(.transition(stroke)))
                        case .circle:
                            promise(.success(.state(stroke)))
                        case .cycle:
                            promise(.success(.transitionCycle(stroke)))
                        }
                    } catch {
                        promise(.failure(.shapeNotRecognized))
                    }
                }
                .eraseToEffect()
            }
        )
    }
}
