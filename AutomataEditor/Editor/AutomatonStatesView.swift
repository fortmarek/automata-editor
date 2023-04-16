import SwiftUI

struct AutomatonStateEditingView: View {
    let automatonState: AutomatonState
    let automatonStateDragged: ((AutomatonState.ID, CGPoint) -> Void)
    let automatonStateFinishedDragging: ((AutomatonState.ID, CGPoint) -> Void)
    
    var body: some View {
        ZStack {
            Circle()
                .fill(.blue)
                .frame(width: 30)
            Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                .frame(width: 25)
        }
        .padding(15)
        // Hack to force the view to render
        // Otherwise, the PKCanvasView is returned in the hitTest method in CanvasView
        .background(Color.black.opacity(0.00001))
        .position(automatonState.dragPoint)
        .offset(
            x: automatonState.currentDragPoint.x - automatonState.dragPoint.x,
            y: automatonState.currentDragPoint.y - automatonState.dragPoint.y
        )
        .gesture(
            DragGesture()
                .onChanged { value in
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

/// View that holds all automaton states.
struct AutomatonStatesView: View {
    var automatonStates: [AutomatonState]
    let stateSymbolChanged: ((AutomatonState.ID, String) -> Void)
    let automatonStateDragged: ((AutomatonState.ID, CGPoint) -> Void)
    let automatonStateFinishedDragging: ((AutomatonState.ID, CGPoint) -> Void)
    let automatonStateRemoved: ((AutomatonState.ID) -> Void)
    let selectedStateForTransition: ((AutomatonState.ID) -> Void)
    let selectedStateForCycle: ((AutomatonState.ID) -> Void)
    let selectedFinalState: ((AutomatonState.ID) -> Void)
    let selectedInitialState: ((AutomatonState.ID) -> Void)
    let currentlySelectedStateForTransition: AutomatonState.ID?
    let mode: EditorFeature.Mode
    let initialStates: [AutomatonState]
    
    var body: some View {
        ForEach(automatonStates) { automatonState in
            TextField(
                "",
                text: Binding(
                    get: { automatonState.name },
                    set: { stateSymbolChanged(automatonState.id, $0) }
                )
            )
            .textInputAutocapitalization(TextInputAutocapitalization.never)
            .autocorrectionDisabled(true)
            .multilineTextAlignment(.center)
            .padding(2)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.white, lineWidth: 2)
            )
            .frame(width: 50, height: 30)
            .position(automatonState.scribblePosition)
            
            Circle()
                .strokeBorder(.white, lineWidth: 4)
                .frame(width: automatonState.radius * 2, height: automatonState.radius * 2)
                .position(automatonState.center)

            if (automatonState.isFinalState) {
                Circle()
                    .strokeBorder(.white, lineWidth: 4)
                    .frame(width: automatonState.radius * 2 - 20, height: automatonState.radius * 2 - 20)
                    .position(automatonState.center)
            }
            
            switch mode {
            case .addingTransition:
                AddTransitionView(
                    point: automatonState.dragPoint,
                    isSelected: automatonState.id == currentlySelectedStateForTransition,
                    selected: { selectedStateForTransition(automatonState.id) }
                )
            case .addingCycle:
                Button(action: { selectedStateForCycle(automatonState.id) }) {
                    ZStack {
                        Circle()
                            .strokeBorder(.blue, lineWidth: 2)
                    }
                }
                .background(Color.black.opacity(0.00001))
                .frame(width: 30)
                .position(automatonState.dragPoint)
            case .addingFinalState:
                if !automatonState.isFinalState {
                    Button(action: { selectedFinalState(automatonState.id) }) {
                        Circle()
                            .strokeBorder(.blue, lineWidth: 2)
                    }
                    .frame(width: 30)
                    .padding(15)
                    .background(Color.black.opacity(0.00001))
                    .position(automatonState.dragPoint)
                }
            case .addingInitialState:
                if !initialStates.map(\.id).contains(automatonState.id) {
                    Button(action: { selectedInitialState(automatonState.id) }) {
                        Circle()
                            .strokeBorder(.blue, lineWidth: 2)
                    }
                    .frame(width: 30)
                    .padding(15)
                    .background(Color.black.opacity(0.00001))
                    .position(automatonState.dragPoint)
                }
            case .erasing:
                Button(action: { automatonStateRemoved(automatonState.id) }) {
                    ZStack {
                        Circle()
                            .fill(.red)
                            .frame(width: 30)
                        Image(systemName: "minus")
                            .foregroundColor(.white)
                            .frame(width: 25)
                    }
                }
                .padding(15)
                .background(Color.black.opacity(0.00001))
                .position(automatonState.dragPoint)
            case .editing:
                AutomatonStateEditingView(
                    automatonState: automatonState,
                    automatonStateDragged: automatonStateDragged,
                    automatonStateFinishedDragging: automatonStateFinishedDragging
                )
            }
        }
    }
}
