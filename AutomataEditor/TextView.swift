//
//  TextView.swift
//  AutomataEditor
//
//  Created by Marek Fořt on 16.03.2021.
//

import UIKit
import SwiftUI

struct TextView: UIViewRepresentable {
    @Binding var text: String
    
    fileprivate let textView: UITextView
    
    init(text: Binding<String>) {
        _text = text
        textView = UITextView()
    }
    
    func makeUIView(context: Context) -> UITextView {
        textView.font = .systemFont(ofSize: 17)
        textView.textContainer.maximumNumberOfLines = 1
        textView.addInteraction(
            UIScribbleInteraction(delegate: context.coordinator)
        )
        textView.delegate = context.coordinator
        
        return textView
    }
    
    func makeCoordinator() -> TextViewCoordinator {
        TextViewCoordinator(self)
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
    }
}

final class TextViewCoordinator: NSObject, UIScribbleInteractionDelegate, UITextViewDelegate {
    private let parent: TextView
    
    init(
        _ parent: TextView
    ) {
        self.parent = parent
    }
    
    func textViewDidChange(_ textView: UITextView) {
        parent.$text.wrappedValue = textView.text
    }
    
    func scribbleInteraction(_ interaction: UIScribbleInteraction, shouldBeginAt location: CGPoint) -> Bool {
        return parent.textView.frame.contains(location)
    }
}
