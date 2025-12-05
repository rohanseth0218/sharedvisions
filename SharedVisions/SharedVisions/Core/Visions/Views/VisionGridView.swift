import SwiftUI

struct VisionGridView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = VisionViewModel()
    @State private var showCreateVision = false
    
    var groupFilter: UUID? = nil
    
    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
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
                    gridView
                }
            }
            .navigationTitle("Gallery")
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
            }
            .task {
                if let userId = authViewModel.currentUser?.id {
                    if let groupId = groupFilter {
                        await viewModel.fetchVisions(groupId: groupId)
                    } else {
                        await viewModel.fetchVisionsForUser(userId: userId)
                    }
                }
            }
            .refreshable {
                if let userId = authViewModel.currentUser?.id {
                    if let groupId = groupFilter {
                        await viewModel.fetchVisions(groupId: groupId)
                    } else {
                        await viewModel.fetchVisionsForUser(userId: userId)
                    }
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
                Text("No Visions Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                
                Text("Create your first shared vision")
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
    
    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(viewModel.visions) { vision in
                    NavigationLink {
                        VisionDetailView(vision: vision, viewModel: viewModel)
                    } label: {
                        VisionGridItem(vision: vision)
                    }
                }
            }
        }
    }
}

struct VisionGridItem: View {
    let vision: Vision
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background image or placeholder
                if let firstImage = vision.generatedImages?.first {
                    AsyncImage(url: URL(string: firstImage.imageUrl)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            placeholderView
                        case .empty:
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color(white: 0.15))
                        @unknown default:
                            placeholderView
                        }
                    }
                } else {
                    placeholderView
                }
                
                // Status overlay for non-completed visions
                if vision.status != .completed {
                    statusOverlay
                }
            }
            .frame(width: geo.size.width, height: geo.size.width)
            .clipped()
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    private var placeholderView: some View {
        ZStack {
            Color(white: 0.15)
            
            VStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.5))
                
                Text(vision.title)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
        }
    }
    
    private var statusOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
            
            VStack(spacing: 8) {
                Image(systemName: vision.status.iconName)
                    .font(.title2)
                    .foregroundStyle(.white)
                
                Text(vision.status.displayName)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }
}

#Preview {
    VisionGridView()
        .environmentObject(AuthViewModel())
}

