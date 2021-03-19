import SwiftUI

struct AutomatonStatesView: View {
    var automatonStates: [AutomatonState]
    let stateSymbolChanged: ((AutomatonState.ID, String) -> Void)
    let automatonStateDragged: ((AutomatonState.ID, CGPoint) -> Void)
    let automatonStateFinishedDragging: ((AutomatonState.ID, CGPoint) -> Void)
    
    @State private var counter = 0
    
    var body: some View {
        ForEach(automatonStates) { automatonState in
            TextView(
                text: Binding(
                    get: { automatonState.name },
                    set: { stateSymbolChanged(automatonState.id, $0) }
                )
            )
            .border(Color.white, width: 2)
            .frame(width: 50, height: 30)
            .position(automatonState.scribblePosition)
            
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 30)
                Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                    .frame(width: 25)
            }
            .position(automatonState.currentDragPoint)
            .offset(
                x: automatonState.dragPoint.x - automatonState.currentDragPoint.x,
                y: automatonState.dragPoint.y - automatonState.currentDragPoint.y
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        counter += 1
                        guard counter % 3 == 1 else { return }
                        automatonStateDragged(
                            automatonState.id,
                            CGPoint(
                                x: automatonState.currentDragPoint.x + value.translation.width,
                                y: automatonState.currentDragPoint.y + value.translation.height
                            )
                        )
                    }
                    .onEnded { value in
                        automatonStateFinishedDragging(
                            automatonState.id,
                            CGPoint(
                                x: automatonState.currentDragPoint.x + value.translation.width,
                                y: automatonState.currentDragPoint.y + value.translation.height
                            )
                        )
                    }
            )
        }
    }
}
