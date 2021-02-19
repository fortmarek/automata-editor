import SwiftUI
import PencilKit

struct CanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.delegate = context.coordinator
        canvasView.drawingPolicy = .anyInput
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 15)
        return canvasView
    }
    
    func makeCoordinator() -> CanvasCoordinator {
        CanvasCoordinator(self)
    }

    func updateUIView(_ canvasView: PKCanvasView, context: Context) { }
}

// MARK: - Coordinator

final class CanvasCoordinator: NSObject {
    private let parent: CanvasView

    init(_ parent: CanvasView) {
        self.parent = parent
    }
}

extension CanvasCoordinator: PKCanvasViewDelegate {
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
    }
}
