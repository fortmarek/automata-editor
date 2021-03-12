import UIKit
import func AVFoundation.AVMakeRect

extension UIImage {
    func modelImage(
        with size: CGSize = CGSize(width: 28, height: 28)
    ) -> UIImage? {
        resize(
            to: size
        )?
        .grayscale()
    }
    
    func resize(to newSize: CGSize) -> UIImage? {
        UIGraphicsImageRenderer(size: newSize)
            .image { _ in
                draw(
                    in: AVMakeRect(
                        aspectRatio: size,
                        insideRect: CGRect(origin: .zero, size: newSize)
                    )
                )
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
        guard
            let context = CGContext(
                data: nil,
                width: Int(size.width),
                height: Int(size.height),
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: bitmapInfo.rawValue
            ),
            let cgImage = cgImage
        else { return nil }
        // Draw image into current context, with specified rectangle using previously defined context (with grayscale colorspace)
        context.draw(cgImage, in: imageRect)
        
        // Create bitmap image info from pixel data in current context
        guard let imageRef: CGImage = context.makeImage() else { return nil }
        
        // Create a new UIImage object
        let newImage: UIImage = UIImage(cgImage: imageRef)
        
        // Return the new grayscale image
        return newImage
    }
}
