import SwiftUI
import Vision
import PencilKit
import ComposableArchitecture

private final class DocumentStore {
    /// Cache of stores, so they are not reinitialized when the document changes - this would cancel any currently-running effects.
    var stores: [UUID: EditorStore] = [:]
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
                        Image(systemName: "plus.circle")
                            .overviewItemStyle()
                        ForEach(["Automaton One", "Automaton Two"], id: \.self) { automaton in
                            NavigationLink(
                                value: ""
                            ) {
                                Image(systemName: "arrow.uturn.down.circle")
                                    .overviewItemStyle()
                            }
                        }
                    }
                        .navigationDestination(
                            for: String.self
                        ) { _ in
                            Text("Hello")
//                            EditorView(store: self.store.scope(state: \.editor, action: OverviewFeature.Action.editor))
                        }
                }
                .padding()
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
                            DocumentPicker(selectedDocument: { viewStore.send(.selectedDocument($0)) } )
                        }
                    }
                }
            }
        }
    }
}
