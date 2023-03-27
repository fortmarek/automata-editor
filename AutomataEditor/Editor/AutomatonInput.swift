import SwiftUI
import ComposableArchitecture

struct AutomatonInput: View {
    let viewStore: ViewStoreOf<EditorFeature>
    
    var body: some View {
        VStack {
            Spacer()
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
                    .foregroundColor(.black)
                    Button(
                        action: {
                            viewStore.send(.removeLastInputSymbol)
                        }
                    ) {
                        Image(systemName: "delete.left")
                            .foregroundColor(.gray)
                    }
                }
                .frame(width: 200)
                .padding(15)
                .background(Color(UIColor.darkGray))
                .cornerRadius(15)
                Spacer()
            }
        }
    }
}
