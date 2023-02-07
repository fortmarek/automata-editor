import SwiftUI
import ComposableArchitecture

extension Image {
    func overviewItemStyle(isSelected: Bool) -> some View {
        self
            .resizable()
            .frame(width: 80, height: 80)
            .padding(.vertical, 50)
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity)
            .background(.white)
            .if(isSelected) {
                $0.overlay(
                    alignment: .bottomTrailing
                ) {
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .padding([.trailing, .bottom], 10)
                }
            }
            .cornerRadius(20)
            .padding(2)
            .if(isSelected) {
                $0
                    .overlay(
                        RoundedRectangle(cornerRadius: 21)
                            .stroke(Color.blue, lineWidth: 2)
                    )
            }
    }
}
