//
//  ContentView.swift
//  AutomataEditor
//
//  Created by Marek Fořt on 17.02.2021.
//

import SwiftUI
import Vision
import PencilKit
import CoreGraphics

struct ContentView: View {
    @State var canvasView: PKCanvasView = .init()
    
    var body: some View {
        VStack {
            CanvasView(canvasView: $canvasView)
            HStack {
                Button("Detect") {
                    detect()
                }
                Button("Clear") {
                    canvasView.drawing = PKDrawing()
                }
                Button("Export") {
                    export()
                    canvasView.drawing = PKDrawing()
                }
            }
        }
    }
    
    private func export() {
        let image = canvasView.drawing.image(
            from: canvasView.drawing.bounds,
            scale: 1.0
        )
        .modelImage()!
        savePNG(image)
    }
    
    func savePNG(_ image: UIImage) {
        guard
            let pngData = image.pngData(),
            let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                .first?
                .appendingPathComponent("\(UUID().uuidString).png")
        else { return }
        try! pngData.write(to: path)
    }
    
    private func detect() {
        let image = canvasView.drawing.image(
            from: canvasView.drawing.bounds,
            scale: 1.0
        )
        .modelImage()!

        let input = try! AutomataClassifierInput(drawingWith: image.cgImage!)
        let classifier = try! AutomataClassifier(configuration: MLModelConfiguration())
        let prediction = try! classifier.prediction(input: input)
        print(prediction.labelProbability)
        
        guard prediction.label == "circle" else {
            canvasView.drawing = PKDrawing()
            return
        }
        
        let lastStroke = canvasView.drawing.strokes[canvasView.drawing.strokes.endIndex - 1]
        let (sumX, sumY, count) = lastStroke.path.interpolatedPoints(by: .distance(50))
            .reduce((CGFloat(0), CGFloat(0), CGFloat(0))) { acc, current in
                (acc.0 + current.location.x, acc.1 + current.location.y, acc.2 + 1)
            }
        let center = CGPoint(x: sumX / count, y: sumY / count)
        
        let sumDistance = lastStroke.path.interpolatedPoints(by: .distance(50))
            .reduce(0) { acc, current in
                acc + abs(center.x - current.location.x) + abs(center.y - current.location.y)
            }
        let radius = sumDistance / count

        let controlPoints: [PKStrokePoint] = stride(from: CGFloat(0), to: 362, by: 2).map { index in
            let radians = index * CGFloat.pi / 180
            
            let location = CGPoint(
                x: CGFloat(center.x + radius * cos(radians)),
                y: CGFloat(center.y + radius * sin(radians))
            )
            return strokePoint(location)
        }
        
        let strokePath = PKStrokePath(
            controlPoints: controlPoints,
            creationDate: Date()
        )
        let stroke = PKStroke(ink: PKInk(.pen), path: strokePath)
        
        canvasView.drawing.strokes[canvasView.drawing.strokes.endIndex - 1] = stroke
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

extension UIImage {
    func modelImage() -> UIImage? {
        resize(
            newSize: CGSize(
                width: 28,
                height: 28
            )
        )?
        .grayscale()
    }
    
    func resize(newSize: CGSize) -> UIImage? {
        UIGraphicsImageRenderer(size: newSize)
            .image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    // Taken and modified from: https://prograils.com/grayscale-conversion-swift
    func grayscale() -> UIImage? {
        // Create image rectangle with current image width/height
        let imageRect: CGRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        // Grayscale color space
        let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceGray()
        
        // Create bitmap content with current image size and grayscale colorspace
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
        let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        )
        guard
            let cgImage = cgImage
        else { return nil }
        // Draw image into current context, with specified rectangle using previously defined context (with grayscale colorspace)
        context?.draw(cgImage, in: imageRect)

        // Create bitmap image info from pixel data in current context
        let imageRef: CGImage = context!.makeImage()!

        // Create a new UIImage object
        let newImage: UIImage = UIImage(cgImage: imageRef)

        // Return the new grayscale image
        return newImage
////        return cgImage?
////            .copy(colorSpace: CGColorSpaceCreateDeviceGray())
////            .map(UIImage.init)
//
//        let context = CIContext(options: nil)
//
////        let shouldInvert: Bool
////        switch traitCollection.userInterfaceStyle {
////        case .light, .unspecified:
////            shouldInvert = false
////        case .dark:
////            shouldInvert = true
////        @unknown default:
////            shouldInvert = true
////        }
//        guard
//            let grayScaleFilter = CIFilter(name: "CIPhotoEffectNoir"),
//            let invertFilter = CIFilter(name: "CIColorInvert"),
//            let output = CIImage(image: self)?
//                .apply(grayScaleFilter)
////                .apply(invertFilter, condition: shouldInvert)
//        else { return nil }
//        let image = context.createCGImage(output, from: output.extent)
//            .map(UIImage.init)
//        return image
    }
}

extension CIImage {
    func apply(_ filter: CIFilter?, condition: Bool = true) -> CIImage {
        guard condition else { return self }
        guard let filter = filter else { return self }
        filter.setValue(self, forKey: kCIInputImageKey)
        return filter.outputImage ?? self
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

