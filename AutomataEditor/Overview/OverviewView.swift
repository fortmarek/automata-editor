import SwiftUI
import Vision
import PencilKit
import ComposableArchitecture

private final class DocumentStore {
    /// Cache of stores, so they are not reinitialized when the document changes - this would cancel any currently-running effects.
//    var stores: [UUID: EditorStore] = [:]
}

extension Image {
    func overviewItemStyle() -> some View {
        self
            .resizable()
            .frame(width: 80, height: 80)
            .padding(.vertical, 50)
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity)
            .background(.white)
            .cornerRadius(20)
    }
}


struct OverviewView: View {
    let store: StoreOf<OverviewFeature>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            NavigationStack {
                ScrollView {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 50),
                            GridItem(.flexible(), spacing: 50),
                            GridItem(.flexible(), spacing: 50),
                            GridItem(.flexible(), spacing: 50),
                        ]
                    ) {
                        Button(
                            action: { viewStore.send(.createNewAutomaton) }
                        ) {
                            VStack {
                                Image(systemName: "plus.circle")
                                    .overviewItemStyle()
                                Text("Create new automaton")
                                    .foregroundColor(.white)
                            }
                        }
                        ForEach(viewStore.automatonFiles, id: \.url) { automaton in
                            Button(
                                action: { viewStore.send(.selectedAutomaton(automaton.url)) }
                            ) {
                                VStack {
                                    Image(systemName: "arrow.uturn.down.circle")
                                        .overviewItemStyle()
                                    Text(automaton.name)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
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
                .padding()
                .onAppear {
                    viewStore.send(.loadAutomata)
                }
                .navigationTitle("My Automata")
                .toolbar {
                    ToolbarItemGroup {
                        Button("Show Files") {
                            viewStore.send(.isDocumentSheetPresentedChanged(true))
                        }
                        .sheet(
                            isPresented: viewStore.binding(
                                get: \.isDocumentSheetPresented,
                                send: { .isDocumentSheetPresentedChanged($0) }
                            )
                        ) {
                            // Things to do when the screen is dismissed
                        } content: {
                            DocumentPicker(selectedDocument: { viewStore.send(.selectedAutomaton($0)) } )
                        }
                    }
                }
            }
        }
    }
}
