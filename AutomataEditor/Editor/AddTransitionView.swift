import SwiftUI

struct AddTransitionView: View {
    var point: CGPoint
    var isSelected: Bool
    let selected: () -> Void
    
    var body: some View {
        Button(action: { selected() }) {
            ZStack {
                Circle()
                    .strokeBorder(.blue, lineWidth: 2)
                
                if isSelected {
                    Circle()
                        .fill(.blue)
                    
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                }
            }
        }
        .frame(width: 30)
        .position(point)
    }
}

struct AddTransitionView_Previews: PreviewProvider {
    static var previews: some View {
        AddTransitionView(
            point: CGPoint(x: 400, y: 500),
            isSelected: false,
            selected: { }
        )
        AddTransitionView(
            point: CGPoint(x: 400, y: 500),
            isSelected: true,
            selected: { }
        )
    }
}
