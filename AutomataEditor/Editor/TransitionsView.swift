import SwiftUI

struct TransitionArrowView: View {
    let transition: AutomatonTransition
    
    var body: some View {
        switch transition.type {
        case let .regular(startPoint, tipPoint, flexPoint):
            Path { path in
                path.arrow(startPoint: startPoint, tipPoint: tipPoint, flexPoint: flexPoint)
            }
            .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round))
            .foregroundColor(.white)
        case .cycle:
            EmptyView()
        }
    }
}

struct TransitionModifierView: View {
    let transition: AutomatonTransition
    let scribblePosition: CGPoint
    let toggleEpsilonInclusion: ((AutomatonState.ID) -> Void)
    let transitionSymbolRemoved: ((AutomatonTransition.ID, String) -> Void)
    let transitionSymbolChanged: ((AutomatonTransition.ID, String) -> Void)
    let transitionSymbolAdded: ((AutomatonTransition.ID) -> Void)
    
    var body: some View {
        VStack(alignment: .center) {
            FlexibleView(
                data: transition.symbols,
                spacing: 3,
                alignment: .leading,
                content: { symbol in
                    Button(
                        action: { transitionSymbolRemoved(transition.id, symbol) }
                    ) {
                        HStack {
                            Text(symbol)
                                .foregroundColor(Color.black)
                            Image(systemName: "xmark")
                                .foregroundColor(Color.black)
                        }
                        .padding(.all, 5)
                        .background(Color.white)
                        .cornerRadius(10)
                    }
                }
            )
            .frame(width: 200)
            HStack {
                Button(
                    action: {
                        toggleEpsilonInclusion(transition.id)
                    }
                ) {
                    Text("ε")
                        .foregroundColor(transition.includesEpsilon ? Color.white : Color.blue)
                        .padding(7)
                        .background(transition.includesEpsilon ? Color.blue : Color.clear)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.blue, lineWidth: 2)
                        )
                }
                TextField(
                    "",
                    text: Binding(
                        get: { transition.currentSymbol },
                        set: { transitionSymbolChanged(transition.id, $0) }
                    )
                )
                .border(Color.white, width: 2)
                .frame(width: 50, height: 30)
                Button(
                    action: { transitionSymbolAdded(transition.id) }
                ) {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .position(scribblePosition)
    }
}

/// View that holds all the transitions.
struct TransitionsView: View {
    let transitions: [AutomatonTransition]
    let toggleEpsilonInclusion: ((AutomatonState.ID) -> Void)
    let transitionSymbolRemoved: ((AutomatonTransition.ID, String) -> Void)
    let transitionSymbolChanged: ((AutomatonTransition.ID, String) -> Void)
    let transitionSymbolAdded: ((AutomatonTransition.ID) -> Void)
    let transitionDragged: ((AutomatonTransition.ID, CGPoint) -> Void)
    let transitionFinishedDragging: ((AutomatonTransition.ID, CGPoint) -> Void)
    
    var body: some View {
        ForEach(transitions) { transition in
            ZStack {
                TransitionArrowView(transition: transition)
                
                if let scribblePosition = transition.scribblePosition {
                    TransitionModifierView(
                        transition: transition,
                        scribblePosition: scribblePosition,
                        toggleEpsilonInclusion: toggleEpsilonInclusion,
                        transitionSymbolRemoved: transitionSymbolRemoved,
                        transitionSymbolChanged: transitionSymbolChanged,
                        transitionSymbolAdded: transitionSymbolAdded
                    )
                }
                if let currentFlexPoint = transition.currentFlexPoint,
                   let flexPoint = transition.flexPoint {
                    ZStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 30)
                        Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                            .frame(width: 25)
                    }
                    .position(currentFlexPoint)
                    .offset(x: flexPoint.x - currentFlexPoint.x, y: flexPoint.y - currentFlexPoint.y)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                transitionDragged(
                                    transition.id,
                                    CGPoint(
                                        x: currentFlexPoint.x + value.translation.width,
                                        y: currentFlexPoint.y + value.translation.height
                                    )
                                )
                            }
                            .onEnded { value in
                                transitionFinishedDragging(
                                    transition.id,
                                    CGPoint(
                                        x: currentFlexPoint.x + value.translation.width,
                                        y: currentFlexPoint.y + value.translation.height
                                    )
                                )
                            }
                    )
                }
            }
        }
    }
}
