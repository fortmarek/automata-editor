import SwiftUI
import Vision
import PencilKit
import ComposableArchitecture

struct OverviewView: View {
    let store: StoreOf<OverviewFeature>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            NavigationStack {
                ScrollView {
                    OverviewGrid(store: store)
                }
                .onAppear {
                    viewStore.send(.loadAutomata)
                }
                .navigationBarTitle("My Automata", displayMode: .inline)
                .alert(
                    "New automaton",
                    isPresented: viewStore.binding(
                        get: \.isAlertForNewAutomatonNamePresented,
                        send: OverviewFeature.Action.isAlertForNewAutomatonNamePresentedChanged
                    ),
                    actions: {
                        TextField(
                            "Automaton name",
                            text: viewStore.binding(
                                get: \.automatonName,
                                send: OverviewFeature.Action.automatonNameChanged
                            )
                        )
                        Button(
                            "OK",
                            action: {
                                viewStore.send(.createNewAutomaton)
                            }
                        )
                        Button(
                            "Cancel",
                            role: .cancel,
                            action: {
                                viewStore.send(.isAlertForNewAutomatonNamePresentedChanged(false))
                            }
                        )
                    },
                    message: {
                        Text("Name your new automaton.")
                    }
                )
                .toolbar {
                    if (viewStore.state.isSelectingFiles) {
                        ToolbarItemGroup(placement: .navigationBarLeading) {
                            Button(action: { viewStore.send(.removeSelectedFiles) }) {
                                Image(systemName: "trash")
                            }
                        }
                        ToolbarItemGroup {
                            Button("Done") {
                                viewStore.send(.doneSelectingFiles)
                            }
                            .bold()
                        }
                    } else {
                        ToolbarItemGroup(placement: .navigationBarLeading) {
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
                        ToolbarItemGroup {
                            Button("Help") {
                                viewStore.send(.isHelpPresentedChanged(true))
                            }
                            .sheet(
                                isPresented: viewStore.binding(
                                    get: \.isHelpPresented,
                                    send: { .isHelpPresentedChanged($0) }
                                )
                            ) {
                                HelpView()
                            }
                            Button("Select") {
                                viewStore.send(.selectFiles)
                            }
                        }
                    }
                }
            }
        }
    }
}
