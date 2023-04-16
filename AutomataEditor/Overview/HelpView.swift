import SwiftUI
import AVKit

struct HelpView: View {
    var body: some View {
        ScrollView {
            VStack {
                Text("Automata editor")
                    .lineLimit(nil)
                    .font(.headline)
                    .padding()
                
                Text("Automata editor is an app that allows you to construct arbitrary nondeterministic finite automata (NFAs) and simulate whether an input is rejected or not. You can construct automata using the top menu as in the image below:")
                    .lineLimit(nil)
                    .font(.body)
                    .padding()
                
                Image("Menu")
                    .resizable()
                    .scaledToFit()
                    .padding()
                
                Text("You can also use your Apple Pencil and draw on the canvas – the app will recognize the individual automata elements (state, transition, cycle) as in the following video:")
                    .lineLimit(nil)
                    .font(.body)
                    .padding()
                
                VideoPlayer(
                    player: AVPlayer(
                        url: URL(fileURLWithPath: Bundle.main.path(forResource: "draw", ofType: "mp4")!)
                    )
                )
                .scaledToFit()
            }
        }
    }
}
