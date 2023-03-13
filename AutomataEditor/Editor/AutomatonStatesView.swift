import SwiftUI

/// View that holds all automaton states.
struct AutomatonStatesView: View {
    var automatonStates: [AutomatonState]
    let stateSymbolChanged: ((AutomatonState.ID, String) -> Void)
    let automatonStateDragged: ((AutomatonState.ID, CGPoint) -> Void)
    let automatonStateFinishedDragging: ((AutomatonState.ID, CGPoint) -> Void)
    let selectedStateForTransition: ((AutomatonState.ID) -> Void)
    let currentlySelectedStateForTransition: AutomatonState.ID?
    let mode: EditorFeature.Mode

    @State private var counter = 0
    
    var body: some View {
        ForEach(automatonStates) { automatonState in
            TextField(
                "",
                text: Binding(
                    get: { automatonState.name },
                    set: { stateSymbolChanged(automatonState.id, $0) }
                )
            )
            .border(Color.white, width: 2)
            .frame(width: 50, height: 30)
            .position(automatonState.scribblePosition)
            
            switch mode {
            case .addingTransition:
                AddTransitionView(
                    point: automatonState.dragPoint,
                    isSelected: automatonState.id == currentlySelectedStateForTransition,
                    selected: { selectedStateForTransition(automatonState.id) }
                )
            case .editing:
                ZStack {
                    Circle()
                        .fill(.blue)
                        .frame(width: 30)
                    Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                        .frame(width: 25)
                }
                .position(automatonState.dragPoint)
                .offset(
                    x: automatonState.currentDragPoint.x - automatonState.dragPoint.x,
                    y: automatonState.currentDragPoint.y - automatonState.dragPoint.y
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            counter += 1
                            guard counter % 8 == 1 else { return }
                            automatonStateDragged(
                                automatonState.id,
                                CGPoint(
                                    x: automatonState.dragPoint.x + value.translation.width,
                                    y: automatonState.dragPoint.y + value.translation.height
                                )
                            )
                        }
                        .onEnded { value in
                            automatonStateFinishedDragging(
                                automatonState.id,
                                CGPoint(
                                    x: automatonState.dragPoint.x + value.translation.width,
                                    y: automatonState.dragPoint.y + value.translation.height
                                )
                            )
                        }
                )
            }
        }
    }
}
