import SwiftUI
import ComposableArchitecture

struct AutomatonInput: View {
    let viewStore: ViewStoreOf<EditorFeature>
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                HStack {
                    TextField(
                        "Automaton input",
                        text: viewStore.binding(
                            get: \.input,
                            send: { .inputChanged($0) }
                        )
                    )
                    .textInputAutocapitalization(TextInputAutocapitalization.never)
                    .autocorrectionDisabled(true)
                    .foregroundColor(.white)
                    Button(
                        action: {
                            viewStore.send(.removeLastInputSymbol)
                        }
                    ) {
                        Image(systemName: "delete.left")
                    }
                }
                .frame(width: 200)
                .padding(15)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(28)
                .shadow(color: Color(UIColor.black.withAlphaComponent(0.08)), radius: 8, x: 0, y: 4)
                .padding([.top, .trailing], 10)
            }
            Spacer()
        }
    }
}
