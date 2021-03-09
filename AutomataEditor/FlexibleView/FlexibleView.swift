import SwiftUI

/// Facade of our view, its main responsibility is to get the available width
/// and pass it down to the real implementation, `_FlexibleView`.
/// This view (and its subviews) has been highly inspied but modified from: https://github.com/zntfdr/FiveStarsCodeSamples/tree/48e493a2b4acd7196c176689a8f3038936f0ed41/Flexible-SwiftUI/Flexible
struct FlexibleView<Data: Collection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Data.Element) -> Content
    @State private var availableWidth: CGFloat = 0
    
    var body: some View {
        ZStack(alignment: Alignment(horizontal: alignment, vertical: .center)) {
            Color.clear
                .frame(height: 1)
                .readSize { size in
                    availableWidth = size.width
                }
            
            _FlexibleView(
                availableWidth: availableWidth,
                data: data,
                spacing: spacing,
                alignment: alignment,
                content: content
            )
        }
    }
}

struct FlexibleView_Previews: PreviewProvider {
    static var previews: some View {
        FlexibleView(
            data: ["A", "B"],
            spacing: 3,
            alignment: .leading,
            content: { text in
                HStack {
                    Text(text)
                        .foregroundColor(Color.black)
                    Button(
                        action: { }
                    ) {
                        Image(systemName: "xmark")
                            .foregroundColor(Color.black)
                    }
                }
                .padding(.all, 5)
                .background(Color.white)
                .cornerRadius(10)
            }
        )
    }
}
