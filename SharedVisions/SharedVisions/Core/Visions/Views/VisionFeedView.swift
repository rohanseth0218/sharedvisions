import SwiftUI

struct VisionFeedView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = VisionViewModel()
    @State private var showCreateVision = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.visions.isEmpty {
                    ProgressView()
                        .tint(.white)
                } else if viewModel.visions.isEmpty {
                    emptyStateView
                } else {
                    feedView
                }
            }
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateVision = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateVision) {
                CreateVisionView(viewModel: viewModel)
                    .environmentObject(authViewModel)
            }
            .task {
                if let userId = authViewModel.currentUser?.id {
                    await viewModel.fetchVisionsForUser(userId: userId)
                }
            }
            .refreshable {
                if let userId = authViewModel.currentUser?.id {
                    await viewModel.fetchVisionsForUser(userId: userId)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundStyle(.white.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("Your Feed is Empty")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                
                Text("Create visions to see them here")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
            }
            
            Button {
                showCreateVision = true
            } label: {
                Label("Create Vision", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.white)
                    .clipShape(Capsule())
            }
        }
    }
    
    private var feedView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.visions) { vision in
                    VisionFeedCard(vision: vision, viewModel: viewModel)
                }
            }
        }
        .scrollContentBackground(.hidden)
    }
}

struct VisionFeedCard: View {
    let vision: Vision
    @ObservedObject var viewModel: VisionViewModel
    @State private var showDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Circle()
                    .fill(Color(white: 0.2))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(vision.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    
                    if let date = vision.createdAt {
                        Text(date.formatted(.relative(presentation: .named)))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                
                Spacer()
                
                Menu {
                    Button {
                        showDetail = true
                    } label: {
                        Label("View Details", systemImage: "info.circle")
                    }
                    
                    if vision.status == .pending || vision.status == .failed {
                        Button {
                            Task {
                                await viewModel.generateImage(for: vision)
                            }
                        } label: {
                            Label("Generate Image", systemImage: "sparkles")
                        }
                    }
                    
                    Button(role: .destructive) {
                        Task {
                            await viewModel.deleteVision(vision.id)
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(8)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            
            // Image
            if let firstImage = vision.generatedImages?.first {
                AsyncImage(url: URL(string: firstImage.imageUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    case .failure:
                        imagePlaceholder
                    case .empty:
                        ProgressView()
                            .frame(height: 400)
                            .frame(maxWidth: .infinity)
                            .background(Color(white: 0.1))
                    @unknown default:
                        imagePlaceholder
                    }
                }
            } else {
                imagePlaceholder
            }
            
            // Actions
            HStack(spacing: 16) {
                // Like/Favorite
                if let firstImage = vision.generatedImages?.first {
                    Button {
                        Task {
                            await viewModel.toggleFavorite(image: firstImage)
                        }
                    } label: {
                        Image(systemName: firstImage.isFavorite ? "heart.fill" : "heart")
                            .font(.title2)
                            .foregroundStyle(firstImage.isFavorite ? .red : .white)
                    }
                }
                
                // Comment (placeholder)
                Button {
                    // Future: Add comment functionality
                } label: {
                    Image(systemName: "bubble.right")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
                
                // Share
                if let firstImage = vision.generatedImages?.first,
                   let url = URL(string: firstImage.imageUrl) {
                    ShareLink(item: url) {
                        Image(systemName: "paperplane")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                }
                
                Spacer()
                
                // Regenerate
                if vision.status == .completed {
                    Button {
                        Task {
                            await viewModel.generateImage(for: vision)
                        }
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            
            // Description
            if let description = vision.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
        }
        .sheet(isPresented: $showDetail) {
            VisionDetailView(vision: vision, viewModel: viewModel)
        }
    }
    
    private var imagePlaceholder: some View {
        ZStack {
            Color(white: 0.1)
            
            VStack(spacing: 12) {
                if vision.status == .generating || viewModel.isGenerating {
                    ProgressView()
                        .tint(.white)
                    Text("Generating your vision...")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                } else {
                    Image(systemName: vision.status.iconName)
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.5))
                    
                    Text(vision.status == .pending ? "Tap to generate" : vision.status.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .frame(height: 400)
        .onTapGesture {
            if vision.status == .pending {
                Task {
                    await viewModel.generateImage(for: vision)
                }
            }
        }
    }
}

#Preview {
    VisionFeedView()
        .environmentObject(AuthViewModel())
}

