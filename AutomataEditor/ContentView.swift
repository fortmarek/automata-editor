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
    @State var drawing: PKDrawing = .init()
    
    var body: some View {
        VStack {
            CanvasView(drawing: $drawing)
            Button("Detect") {
                let image = drawing.image(
                    from: drawing.bounds,
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
//                let model = try! VNCoreMLModel(
//                    for: AutomataClassifier(configuration: MLModelConfiguration()).model
//                )
//                let request = VNCoreMLRequest(
//                    model: model
//                ) { request, error in
//                    if let _ = error {
//                        return
//                    } else {
//                        print(request.results)
//                    }
//                }
//                guard let ciImage = CIImage(image: image.resize(newSize: CGSize(width: 28, height: 28))!) else {
//                  print("Unable to create CIImage")
//                  return
//                }
//                DispatchQueue.global(qos: .userInitiated).async {
//                  let handler = VNImageRequestHandler(
//                    ciImage: ciImage,
//                    orientation: .up
//                  )
//                  do {
//                    try handler.perform([request])
//                  } catch {
//                    print("Failed to perform classification: \(error)")
//                  }
//                }
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

