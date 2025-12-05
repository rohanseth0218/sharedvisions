import SwiftUI

struct PhotoUploadView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @ObservedObject var viewModel: ProfileViewModel
    
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var isPrimary = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.98, green: 0.97, blue: 1.0)
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    // Preview
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 200, height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "person.crop.rectangle")
                                .font(.system(size: 60))
                                .foregroundStyle(Color(red: 0.4, green: 0.2, blue: 0.6).opacity(0.5))
                            
                            Text("Select a photo of yourself")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 200, height: 200)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
                    }
                    
                    // Source buttons
                    HStack(spacing: 16) {
                        Button {
                            showImagePicker = true
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.title2)
                                Text("Gallery")
                                    .font(.caption)
                            }
                            .foregroundStyle(Color(red: 0.4, green: 0.2, blue: 0.6))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        Button {
                            showCamera = true
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "camera")
                                    .font(.title2)
                                Text("Camera")
                                    .font(.caption)
                            }
                            .foregroundStyle(Color(red: 0.4, green: 0.2, blue: 0.6))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal)
                    
                    // Primary toggle
                    if selectedImage != nil {
                        Toggle(isOn: $isPrimary) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Set as primary photo")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text("This photo will be used first for AI generation")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .tint(Color(red: 0.4, green: 0.2, blue: 0.6))
                        .padding()
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }
                    
                    // Tips
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Photo Tips")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TipRow(icon: "face.smiling", text: "Clear view of your face")
                        TipRow(icon: "sun.max", text: "Good lighting")
                        TipRow(icon: "person", text: "Just you in the photo")
                        TipRow(icon: "rectangle.portrait", text: "Front-facing works best")
                    }
                    .padding()
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.top, 40)
                
                // Upload button
                if selectedImage != nil {
                    VStack {
                        Spacer()
                        
                        Button {
                            uploadPhoto()
                        } label: {
                            if viewModel.isUploading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Upload Photo")
                                    .font(.headline)
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.5, green: 0.3, blue: 0.7),
                                    Color(red: 0.4, green: 0.2, blue: 0.6)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                        .disabled(viewModel.isUploading)
                    }
                }
            }
            .navigationTitle("Add Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .sheet(isPresented: $showCamera) {
                ImagePicker(image: $selectedImage, sourceType: .camera)
            }
        }
    }
    
    private func uploadPhoto() {
        guard let image = selectedImage,
              let userId = authViewModel.currentUser?.id else { return }
        
        Task {
            if let _ = await viewModel.uploadPhoto(userId: userId, image: image, isPrimary: isPrimary) {
                dismiss()
            }
        }
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color(red: 0.4, green: 0.2, blue: 0.6))
                .frame(width: 20)
            
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    PhotoUploadView(viewModel: ProfileViewModel())
        .environmentObject(AuthViewModel())
}

