import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showPhotoUpload = false
    @State private var showSettings = false
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.98, green: 0.97, blue: 1.0)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile header
                        profileHeader
                        
                        // Photos section
                        photosSection
                        
                        // Stats section
                        statsSection
                        
                        // Settings section
                        settingsSection
                        
                        Spacer(minLength: 40)
                    }
                    .padding()
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showPhotoUpload) {
                PhotoUploadView(viewModel: viewModel)
                    .environmentObject(authViewModel)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .onAppear {
                print("👤 ProfileView appeared")
                print("👤 isAuthenticated: \(authViewModel.isAuthenticated)")
                print("👤 currentUser: \(String(describing: authViewModel.currentUser))")
                
                // If authenticated but no user, try to reload in a detached task
                if authViewModel.isAuthenticated && authViewModel.currentUser == nil {
                    print("👤 User is authenticated but currentUser is nil, reloading...")
                    Task {
                        await authViewModel.checkSession()
                        print("👤 After reload - currentUser: \(String(describing: authViewModel.currentUser))")
                        if let userId = authViewModel.currentUser?.id {
                            await viewModel.fetchUserPhotos(userId: userId)
                        }
                    }
                } else if let userId = authViewModel.currentUser?.id {
                    Task {
                        await viewModel.fetchUserPhotos(userId: userId)
                    }
                }
            }
        }
    }
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                if let avatarUrl = authViewModel.currentUser?.avatarUrl,
                   let url = URL(string: avatarUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            avatarPlaceholder
                        }
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                } else {
                    avatarPlaceholder
                }
                
                Button {
                    showImagePicker = true
                } label: {
                    Image(systemName: "camera.fill")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(Color(red: 0.4, green: 0.2, blue: 0.6))
                        .clipShape(Circle())
                }
                .offset(x: 4, y: 4)
            }
            
            // Name
            VStack(spacing: 4) {
                Text(authViewModel.currentUser?.fullName ?? "User")
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let username = authViewModel.currentUser?.username {
                    Text("@\(username)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.top, 20)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .onChange(of: selectedImage) { _, newImage in
            if let image = newImage,
               let userId = authViewModel.currentUser?.id {
                Task {
                    _ = await viewModel.uploadAvatar(userId: userId, image: image)
                }
            }
        }
    }
    
    private var avatarPlaceholder: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.5, green: 0.3, blue: 0.7),
                        Color(red: 0.4, green: 0.2, blue: 0.6)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 100, height: 100)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.white)
            )
    }
    
    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("My Photos")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    showPhotoUpload = true
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(.subheadline)
                        .foregroundStyle(Color(red: 0.4, green: 0.2, blue: 0.6))
                }
            }
            
            Text("Upload photos of yourself for AI image generation")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if viewModel.userPhotos.isEmpty {
                Button {
                    showPhotoUpload = true
                } label: {
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.rectangle.badge.plus")
                            .font(.system(size: 30))
                            .foregroundStyle(Color(red: 0.4, green: 0.2, blue: 0.6).opacity(0.6))
                        
                        Text("Upload your first photo")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.userPhotos) { photo in
                            PhotoThumbnail(photo: photo, viewModel: viewModel)
                        }
                        
                        // Add more button
                        Button {
                            showPhotoUpload = true
                        } label: {
                            VStack {
                                Image(systemName: "plus")
                                    .font(.title2)
                            }
                            .frame(width: 80, height: 80)
                            .background(Color(red: 0.4, green: 0.2, blue: 0.6).opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var statsSection: some View {
        HStack(spacing: 0) {
            StatItem(value: "\(viewModel.userPhotos.count)", label: "Photos")
            
            Divider()
                .frame(height: 40)
            
            StatItem(value: "0", label: "Visions")
            
            Divider()
                .frame(height: 40)
            
            StatItem(value: "0", label: "Groups")
        }
        .padding(.vertical, 16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var settingsSection: some View {
        VStack(spacing: 0) {
            SettingsRow(icon: "person.circle", title: "Edit Profile") {
                // Edit profile action
            }
            
            Divider().padding(.leading, 52)
            
            SettingsRow(icon: "bell", title: "Notifications") {
                // Notifications action
            }
            
            Divider().padding(.leading, 52)
            
            SettingsRow(icon: "questionmark.circle", title: "Help & Support") {
                // Help action
            }
            
            Divider().padding(.leading, 52)
            
            SettingsRow(icon: "rectangle.portrait.and.arrow.right", title: "Sign Out", isDestructive: true) {
                Task {
                    await authViewModel.signOut()
                }
            }
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct PhotoThumbnail: View {
    let photo: UserPhoto
    @ObservedObject var viewModel: ProfileViewModel
    @State private var showActions = false
    
    var body: some View {
        AsyncImage(url: URL(string: photo.photoUrl)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            default:
                Color(white: 0.9)
            }
        }
        .frame(width: 80, height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            photo.isPrimary ?
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(red: 0.4, green: 0.2, blue: 0.6), lineWidth: 2)
            : nil
        )
        .overlay(
            photo.isPrimary ?
            Text("Primary")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color(red: 0.4, green: 0.2, blue: 0.6))
                .clipShape(Capsule())
                .offset(y: 30)
            : nil
        )
        .onTapGesture {
            showActions = true
        }
        .confirmationDialog("Photo Options", isPresented: $showActions) {
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deletePhoto(photo)
                }
            }
        }
    }
}

struct StatItem: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    var isDestructive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(isDestructive ? .red : Color(red: 0.4, green: 0.2, blue: 0.6))
                    .frame(width: 28)
                
                Text(title)
                    .foregroundStyle(isDestructive ? .red : .primary)
                
                Spacer()
                
                if !isDestructive {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    Text("Edit Profile")
                    Text("Change Password")
                    Text("Privacy")
                }
                
                Section("Preferences") {
                    Text("Notifications")
                    Text("Appearance")
                }
                
                Section("About") {
                    Text("Help Center")
                    Text("Terms of Service")
                    Text("Privacy Policy")
                    Text("Version 1.0.0")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
}

