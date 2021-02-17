//
//  ContentView.swift
//  AutomataEditor
//
//  Created by Marek Fořt on 17.02.2021.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            CanvasView()
            Button("Detect") {
                print("Detect!!")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

import PencilKit
struct CanvasView: UIViewRepresentable {
    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
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
//        canvasView.dra
    }
}
