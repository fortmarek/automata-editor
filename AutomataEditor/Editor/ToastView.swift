import SwiftUI

struct ToastView: View {
    let image: String?
    let imageColor: Color
    let title: String
    let subtitle: String?
    
    var body: some View {
        HStack(spacing: 16) {
            if let image = image {
                Image(systemName: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundColor(imageColor)
            }
            
            VStack(alignment: .center) {
                Text(title)
                    .lineLimit(1)
                    .font(.headline)
                    .foregroundColor(.white)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .lineLimit(1)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(image == nil ? .horizontal : .trailing)
        }
        .padding(.horizontal)
        .frame(height: 56)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(28)
        .shadow(color: Color(UIColor.black.withAlphaComponent(0.08)), radius: 8, x: 0, y: 4)
        .padding(.top, 20)
    }
}
