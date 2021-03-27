//
//  EditorButton.swift
//  AutomataEditor
//
//  Created by Marek Fořt on 27.03.2021.
//

import SwiftUI

struct EditorButton: View {
    let isSelected: Bool
    let image: Image
    let action: () -> Void
    var body: some View {
        Button(
            action: {
                action()
            }
        ) {
            image
                .resizable()
                .frame(width: 12, height: 12)
                .foregroundColor(isSelected ? Color.white : Color.blue)
                .padding(7)
                .background(isSelected ? Color.blue : Color.clear)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.blue, lineWidth: 2)
                )
        }
    }
}

