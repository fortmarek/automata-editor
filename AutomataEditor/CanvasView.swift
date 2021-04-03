import SwiftUI
import PencilKit

enum Tool: String, Codable {
    case pen
    case eraser
    
    fileprivate var pkTool: PKTool {
        switch self {
        case .pen:
            return PKInkingTool(.pen, color: .black, width: 15)
        case .eraser:
            return PKEraserTool(.vector)
        }
    }
}

struct CanvasView: UIViewRepresentable {
    @Binding var shouldDeleteLastStroke: Bool
    @Binding var strokes: [Stroke]
    var tool: Tool
    
    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.delegate = context.coordinator
        canvasView.drawingGestureRecognizer.delegate = context.coordinator
        canvasView.drawingPolicy = .default
        canvasView.tool = tool.pkTool
        return canvasView
    }
    
    func makeCoordinator() -> CanvasCoordinator {
        CanvasCoordinator(self)
    }

    func updateUIView(_ canvasView: PKCanvasView, context: Context) {
        canvasView.tool = tool.pkTool
        canvasView.drawing.strokes = strokes.map { $0.pkStroke() }
        if shouldDeleteLastStroke {
            if !canvasView.drawing.strokes.isEmpty {
                canvasView.drawing.strokes.removeLast()
            }
            shouldDeleteLastStroke = false
        }
    }
}

// MARK: - Coordinator

final class CanvasCoordinator: NSObject {
    private let parent: CanvasView
    fileprivate var shouldUpdateStrokes = false
    
    init(_ parent: CanvasView) {
        self.parent = parent
    }
}

extension CanvasCoordinator: PKCanvasViewDelegate {    
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        guard shouldUpdateStrokes else { return }
        shouldUpdateStrokes = false
        parent.strokes = canvasView.drawing.strokes.map(Stroke.init)
    }
}

extension CanvasCoordinator: UIGestureRecognizerDelegate {
    func canvasViewDidEndUsingTool(_ canvasView: PKCanvasView) {
        shouldUpdateStrokes = true
    }
}
