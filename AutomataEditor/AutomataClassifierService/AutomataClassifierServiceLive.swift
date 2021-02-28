import Foundation
import CoreML
import UIKit
import PencilKit
import ComposableArchitecture
import Combine

private enum AutomataShapeType: String {
    case circle
    case arrow
}

extension AutomataClassifierService {
    static func live() -> Self {
        Self(
            recognizeStroke: { stroke in
                Future<AutomataShape, AutomataClassifierError> { promise in
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
                            promise(.failure(.shapeNotRecognized))
                            return
                        }
                            

                        let input = try AutomataClassifierInput(drawingWith: cgImage)
                        let classifier = try AutomataClassifier(configuration: MLModelConfiguration())
                        let prediction = try classifier.prediction(input: input)
                        print(prediction.labelProbability)
                        if let automataShapeType = AutomataShapeType(rawValue: prediction.label) {
                            switch automataShapeType {
                            case .arrow:
                                promise(.success(.transition(stroke)))
                            case .circle:
                                promise(.success(.state(stroke)))
                            }
                        } else {
                            promise(.failure(.shapeNotRecognized))
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
