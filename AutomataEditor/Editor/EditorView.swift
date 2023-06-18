import SwiftUI
import Vision
import PencilKit
import ComposableArchitecture

struct EditorView: View {
    let store: StoreOf<EditorFeature>
    @State private var hasAppeared = false
    
    var body: some View {
        WithViewStore(store) { viewStore in
            GeometryReader { geometry in
                ZStack {
                    CanvasView(
                        tool: viewStore.state.tool,
                        strokesChanged: { viewStore.send(.strokesChanged($0)) },
                        currentVisibleScrollViewRectChanged: { viewStore.send(.currentVisibleScrollViewRectChanged($0)) }
                    ) {
                        ZStack {
                            TransitionsView(
                                transitions: viewStore.transitions,
                                toggleEpsilonInclusion: { viewStore.send(.toggleEpsilonInclusion($0)) },
                                transitionSymbolRemoved: { viewStore.send(.transitionSymbolRemoved($0, $1)) },
                                transitionSymbolChanged: { viewStore.send(.transitionSymbolChanged($0, $1)) },
                                transitionSymbolAdded: { viewStore.send(.transitionSymbolAdded($0)) },
                                transitionRemoved: { viewStore.send(.transitionRemoved($0)) },
                                transitionDragged: {
                                    viewStore.send(.transitionFlexPointChanged($0, $1))
                                },
                                transitionFinishedDragging: {
                                    viewStore.send(.transitionFlexPointFinishedDragging($0, $1))
                                },
                                mode: viewStore.mode
                            )
                            AutomatonStatesView(
                                automatonStates: viewStore.automatonStates,
                                stateSymbolChanged: { viewStore.send(.stateSymbolChanged($0, $1)) },
                                automatonStateDragged: { viewStore.send(.stateDragPointChanged($0, $1)) },
                                automatonStateFinishedDragging: { viewStore.send(.stateDragPointFinishedDragging($0, $1)) },
                                automatonStateRemoved: { viewStore.send(.automatonStateRemoved($0)) },
                                selectedStateForTransition: { viewStore.send(.selectedStateForTransition($0)) },
                                selectedStateForCycle: { viewStore.send(.selectedStateForCycle($0)) },
                                selectedFinalState: { viewStore.send(.selectedFinalState($0)) },
                                selectedInitialState: { viewStore.send(.selectedInitialState($0)) },
                                currentlySelectedStateForTransition: viewStore.currentlySelectedStateForTransition,
                                mode: viewStore.mode,
                                initialStates: viewStore.initialStates
                            )
                        }
                    }
                    VStack {
                        Button() {
                            viewStore.send(.dismissToast)
                        } label: {
                            if viewStore.isAutomatonOutputVisible {
                                ToastView(
                                    image: viewStore.automatonOutput.image,
                                    imageColor: viewStore.automatonOutput.imageColor,
                                    title: viewStore.automatonOutput.title,
                                    subtitle: viewStore.automatonOutput.subtitle
                                )
                                .transition(AnyTransition.move(edge: .top))
                                .animation(.spring(), value: viewStore.automatonOutput.title)
                            }
                        }
                        .animation(.spring(), value: viewStore.isAutomatonOutputVisible)
                        Spacer()
                    }
                    AutomatonInput(viewStore: viewStore)
                }
                .toolbar {
                   EditorToolbar(viewStore: viewStore)
                }
                .onChange(of: viewStore.state, perform: { viewStore.send(.stateUpdated($0)) })
                .onAppear {
                    viewStore.send(.viewSizeChanged(geometry.size))
                    if !hasAppeared {
                        viewStore.send(.onAppear)
                    }
                }
                .alert(
                    "Clear automaton",
                    isPresented: viewStore.binding(get: \.isClearAlertPresented, send: { _ in .clearAlertDismissed })
                ) {
                    Button("Delete", role: .destructive) {
                        viewStore.send(.clear)
                    }
                } message: {
                    Text("Do you really want to clear this automaton? This can't be undone.")
                }
            }
        }
    }
}

private extension EditorFeature.AutomatonOutput {
    var image: String {
        switch self {
        case .success:
            return "checkmark.circle"
        case .failure:
            return "xmark.circle"
        }
    }
    
    var imageColor: Color {
        switch self {
        case .success:
            return .green
        case .failure:
            return .red
        }
    }
    
    var title: String {
        switch self {
        case .success:
            return "Input accepted"
        case .failure:
            return "Input rejected"
        }
    }
    
    var subtitle: String? {
        switch self {
        case .success:
            return nil
        case let .failure(reason):
            return reason
        }
    }
}
