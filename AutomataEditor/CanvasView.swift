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

struct CanvasView<Content: View>: UIViewRepresentable {
    var tool: Tool
    @ViewBuilder var view: Content

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = max(UIScreen.main.bounds.width / 4000, UIScreen.main.bounds.height / 4000)
        scrollView.maximumZoomScale = 2.5

        let contentView = UIView()
        contentView.frame.size = CGSize(width: 4000, height: 4000)
        scrollView.addSubview(contentView)

        let canvasView = PKCanvasView()
        canvasView.frame.size = CGSize(width: 4000, height: 4000)
        canvasView.delegate = context.coordinator
        canvasView.drawingGestureRecognizer.delegate = context.coordinator
        canvasView.drawingPolicy = .default
        canvasView.tool = tool.pkTool
        contentView.addSubview(canvasView)
        context.coordinator.canvasView = canvasView

        context.coordinator.viewForZooming = contentView
        
        context.coordinator.hostingController = UIHostingController(rootView: view)
        
        guard let overlayView = context.coordinator.hostingController?.view else { return scrollView }
        overlayView.backgroundColor = .clear
        overlayView.frame = canvasView.frame
        contentView.addSubview(overlayView)

        return scrollView
    }

    func makeCoordinator() -> CanvasCoordinator<Content> {
        CanvasCoordinator(self)
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        let canvasView = context.coordinator.canvasView!
        canvasView.tool = tool.pkTool
        
        context.coordinator.hostingController?.rootView = view
    }
}

// MARK: - Coordinator

final class CanvasCoordinator<Content>: NSObject, PKCanvasViewDelegate, UIGestureRecognizerDelegate where Content: View {
    private let parent: CanvasView<Content>
    var viewForZooming: UIView?
    var canvasView: PKCanvasView!
    var hostingController: UIHostingController<Content>!

    init(_ parent: CanvasView<Content>) {
        self.parent = parent
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        viewForZooming
    }
}
