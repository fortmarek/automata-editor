//
//  ContentView.swift
//  AutomataEditor
//
//  Created by Marek Fořt on 17.02.2021.
//

import SwiftUI
import Vision
import PencilKit

struct ContentView: View {
    @State var canvasView: PKCanvasView = .init()
    
    var body: some View {
        VStack {
            CanvasView(canvasView: $canvasView)
            HStack {
                Button("Detect") {
                    let image = canvasView.drawing.image(
                        from: canvasView.drawing.bounds,
                        scale: 1.0
                    )
                    .resize(
                        newSize: CGSize(
                            width: 28,
                            height: 28
                        )
                    )!

                    let input = try! AutomataClassifierInput(drawingWith: image.cgImage!)
                    let classifier = try! AutomataClassifier(configuration: MLModelConfiguration())
                    let prediction = try! classifier.prediction(input: input)
                    print(prediction.labelProbability)
                }
                Button("Clear") {
                    canvasView.drawing = PKDrawing()
                }
            }
        }
    }
}

extension UIImage
{
    func resize(newSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        self.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

