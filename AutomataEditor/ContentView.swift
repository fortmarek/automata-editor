//
//  ContentView.swift
//  AutomataEditor
//
//  Created by Marek Fořt on 17.02.2021.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        CanvasView()
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
        canvasView.drawingPolicy = .anyInput
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 15)
        return canvasView
    }

    func updateUIView(_ canvasView: PKCanvasView, context: Context) { }
}
