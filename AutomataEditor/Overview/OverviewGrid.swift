import SwiftUI
import ComposableArchitecture

struct OverviewGrid: View {
    let store: StoreOf<OverviewFeature>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 50),
                    GridItem(.flexible(), spacing: 50),
                    GridItem(.flexible(), spacing: 50),
                    GridItem(.flexible(), spacing: 50),
                ]
            ) {
                Button(
                    action: { viewStore.send(.isAlertForNewAutomatonNamePresentedChanged(true)) }
                ) {
                    VStack {
                        Image(systemName: "plus.circle")
                            .overviewItemStyle(isSelected: false)
                        Text("Create new automaton")
                            .foregroundColor(.white)
                    }
                }
                ForEach(viewStore.automatonFiles, id: \.url) { automaton in
                    Button(
                        action: { viewStore.send(.selectedAutomaton(automaton.url)) }
                    ) {
                        VStack {
                            Image(systemName: "pencil.and.outline")
                                .overviewItemStyle(
                                    isSelected: viewStore.selectedAutomatonFileIDs.contains(automaton.id)
                                )
                            Text(automaton.name)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .padding()
            .navigationDestination(
                isPresented: viewStore.binding(
                    get: \.isEditorPresented,
                    send: OverviewFeature.Action.isEditorPresentedChanged
                )
            ) {
                IfLetStore(
                    self.store.scope(
                        state: \.editor,
                        action: OverviewFeature.Action.editor
                    )
                ) {
                    EditorView(store: $0)
                }
            }
        }
    }
}
