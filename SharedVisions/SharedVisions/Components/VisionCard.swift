import SwiftUI

struct VisionCard: View {
    let vision: Vision
    var showGroup: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image
            if let firstImage = vision.generatedImages?.first {
                AsyncImage(url: URL(string: firstImage.imageUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        imagePlaceholder
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .background(Color(white: 0.95))
                    @unknown default:
                        imagePlaceholder
                    }
                }
                .frame(height: 200)
                .clipped()
            } else {
                imagePlaceholder
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Title
                Text(vision.title)
                    .font(.headline)
                    .lineLimit(2)
                
                // Description
                if let description = vision.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                // Footer
                HStack {
                    // Status badge
                    HStack(spacing: 4) {
                        Image(systemName: vision.status.iconName)
                            .font(.caption2)
                        Text(vision.status.displayName)
                            .font(.caption)
                    }
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.1))
                    .clipShape(Capsule())
                    
                    Spacer()
                    
                    // Date
                    if let date = vision.createdAt {
                        Text(date.formatted(.relative(presentation: .named)))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
    }
    
    private var imagePlaceholder: some View {
        ZStack {
            Color(white: 0.95)
            
            VStack(spacing: 8) {
                Image(systemName: vision.status == .generating ? "sparkles" : "photo")
                    .font(.title)
                    .foregroundStyle(Color(red: 0.4, green: 0.2, blue: 0.6).opacity(0.5))
                
                if vision.status == .generating {
                    Text("Generating...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(height: 200)
    }
    
    private var statusColor: Color {
        switch vision.status {
        case .pending: return .orange
        case .generating: return .blue
        case .completed: return .green
        case .failed: return .red
        }
    }
}

#Preview {
    VisionCard(
        vision: Vision(
            id: UUID(),
            groupId: UUID(),
            createdBy: UUID(),
            title: "Beach Vacation in Bali",
            description: "A week of relaxation on beautiful beaches",
            targetMembers: [],
            status: .completed,
            createdAt: Date()
        )
    )
    .padding()
}

