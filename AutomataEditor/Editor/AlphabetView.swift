import SwiftUI

struct AlphabetView: View {
    let currentAlphabetSymbol: String
    let currentAlphabetSymbolChanged: ((String) -> Void)
    let alphabetSymbols: [String]
    let addedCurrentAlphabetSymbol: (() -> Void)
    let removedAlphabetSymbol: ((String) -> Void)
    let outputString: String
    
    var body: some View {
        VStack(alignment: .center) {
            Text("Alphabet")
            HStack {
                TextView(
                    text: Binding(
                        get: { currentAlphabetSymbol },
                        set: { currentAlphabetSymbolChanged($0) }
                    )
                )
                .border(Color.white)
                .frame(width: 100, height: 30)
                Button(
                    action: { addedCurrentAlphabetSymbol() }
                ) {
                    Image(systemName: "plus.circle.fill")
                }
            }
            ForEach(alphabetSymbols, id: \.self) { symbol in
                HStack {
                    Text(symbol)
                    Button(
                        action: { removedAlphabetSymbol(symbol) }
                    ) {
                        Image(systemName: "trash.fill")
                    }
                }
            }
            Text("Output: \(outputString)")
                .frame(width: 140)
        }
        .position(x: 70, y: 100)
    }
}
