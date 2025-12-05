import SwiftUI

struct VisionDetailView: View {
    let vision: Vision
    @ObservedObject var viewModel: VisionViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedImageIndex = 0
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Image carousel
                        if let images = vision.generatedImages, !images.isEmpty {
                            TabView(selection: $selectedImageIndex) {
                                ForEach(Array(images.enumerated()), id: \.element.id) { index, image in
                                    AsyncImage(url: URL(string: image.imageUrl)) { phase in
                                        switch phase {
                                        case .success(let img):
                                            img
                                                .resizable()
                                                .scaledToFit()
                                        case .failure:
                                            imagePlaceholder
                                        case .empty:
                                            ProgressView()
                                                .tint(.white)
                                        @unknown default:
                                            imagePlaceholder
                                        }
                                    }
                                    .tag(index)
                                }
                            }
                            .tabViewStyle(.page)
                            .frame(height: UIScreen.main.bounds.width)
                            
                            // Page indicator
                            if images.count > 1 {
                                HStack(spacing: 6) {
                                    ForEach(0..<images.count, id: \.self) { index in
                                        Circle()
                                            .fill(index == selectedImageIndex ? .white : .white.opacity(0.4))
                                            .frame(width: 6, height: 6)
                                    }
                                }
                                .padding(.vertical, 12)
                            }
                        } else {
                            imagePlaceholder
                                .frame(height: UIScreen.main.bounds.width)
                        }
                        
                        // Details
                        VStack(alignment: .leading, spacing: 20) {
                            // Title and status
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(vision.title)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                    
                                    HStack(spacing: 8) {
                                        Image(systemName: vision.status.iconName)
                                            .font(.caption)
                                        Text(vision.status.displayName)
                                            .font(.caption)
                                    }
                                    .foregroundStyle(statusColor)
                                }
                                
                                Spacer()
                                
                                // Favorite button
                                if let image = vision.generatedImages?[safe: selectedImageIndex] {
                                    Button {
                                        Task {
                                            await viewModel.toggleFavorite(image: image)
                                        }
                                    } label: {
                                        Image(systemName: image.isFavorite ? "heart.fill" : "heart")
                                            .font(.title2)
                                            .foregroundStyle(image.isFavorite ? .red : .white)
                                    }
                                }
                            }
                            
                            // Description
                            if let description = vision.description, !description.isEmpty {
                                Text(description)
                                    .font(.body)
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                            
                            // Date
                            if let date = vision.createdAt {
                                HStack {
                                    Image(systemName: "calendar")
                                        .font(.caption)
                                    Text(date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                }
                                .foregroundStyle(.white.opacity(0.5))
                            }
                            
                            Divider()
                                .background(Color.white.opacity(0.2))
                            
                            // Actions
                            VStack(spacing: 12) {
                                // Generate / Regenerate
                                Button {
                                    Task {
                                        await viewModel.generateImage(for: vision)
                                    }
                                } label: {
                                    Label(
                                        vision.generatedImages?.isEmpty ?? true ? "Generate Image" : "Generate New Version",
                                        systemImage: "sparkles"
                                    )
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color(red: 0.4, green: 0.2, blue: 0.6))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .disabled(viewModel.isGenerating)
                                
                                // Share
                                if let image = vision.generatedImages?[safe: selectedImageIndex],
                                   let url = URL(string: image.imageUrl) {
                                    ShareLink(item: url) {
                                        Label("Share", systemImage: "square.and.arrow.up")
                                            .font(.headline)
                                            .foregroundStyle(Color(red: 0.4, green: 0.2, blue: 0.6))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 14)
                                            .background(Color(red: 0.4, green: 0.2, blue: 0.6).opacity(0.15))
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                }
                                
                                // Delete
                                Button(role: .destructive) {
                                    showDeleteConfirmation = true
                                } label: {
                                    Label("Delete Vision", systemImage: "trash")
                                        .font(.subheadline)
                                        .foregroundStyle(.red)
                                }
                                .padding(.top, 8)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            Task {
                                await viewModel.generateImage(for: vision)
                            }
                        } label: {
                            Label("Generate New", systemImage: "sparkles")
                        }
                        
                        if let image = vision.generatedImages?[safe: selectedImageIndex],
                           let url = URL(string: image.imageUrl) {
                            ShareLink(item: url) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                        }
                        
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .confirmationDialog("Delete Vision?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    Task {
                        let success = await viewModel.deleteVision(vision.id)
                        if success {
                            dismiss()
                        }
                    }
                }
            } message: {
                Text("This will permanently delete this vision and all generated images.")
            }
        }
    }
    
    private var imagePlaceholder: some View {
        ZStack {
            Color(white: 0.1)
            
            VStack(spacing: 12) {
                if viewModel.isGenerating {
                    ProgressView()
                        .tint(.white)
                    Text("Generating...")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.5))
                    
                    Text("No image generated yet")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
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

// Safe array subscript
extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    VisionDetailView(
        vision: Vision(
            id: UUID(),
            groupId: UUID(),
            createdBy: UUID(),
            title: "Beach Vacation in Bali",
            description: "A relaxing week on the beautiful beaches of Bali, watching sunsets together.",
            targetMembers: [],
            status: .completed,
            createdAt: Date()
        ),
        viewModel: VisionViewModel()
    )
}

