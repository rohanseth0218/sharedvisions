import SwiftUI

struct AsyncImageView: View {
    let url: String?
    var contentMode: ContentMode = .fill
    var cornerRadius: CGFloat = 0
    
    var body: some View {
        if let urlString = url, let imageUrl = URL(string: urlString) {
            AsyncImage(url: imageUrl) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                        
                case .failure:
                    failurePlaceholder
                    
                case .empty:
                    loadingPlaceholder
                    
                @unknown default:
                    loadingPlaceholder
                }
            }
        } else {
            emptyPlaceholder
        }
    }
    
    private var loadingPlaceholder: some View {
        ZStack {
            Color(white: 0.95)
            ProgressView()
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
    
    private var failurePlaceholder: some View {
        ZStack {
            Color(white: 0.95)
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
    
    private var emptyPlaceholder: some View {
        ZStack {
            Color(white: 0.95)
            Image(systemName: "photo")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

#Preview {
    VStack(spacing: 20) {
        AsyncImageView(
            url: "https://example.com/image.jpg",
            cornerRadius: 12
        )
        .frame(width: 200, height: 200)
        
        AsyncImageView(
            url: nil,
            cornerRadius: 12
        )
        .frame(width: 200, height: 200)
    }
}

