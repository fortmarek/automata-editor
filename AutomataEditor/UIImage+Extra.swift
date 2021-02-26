import UIKit

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
