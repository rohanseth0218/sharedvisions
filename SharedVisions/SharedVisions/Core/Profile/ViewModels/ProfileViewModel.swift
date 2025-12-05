import Foundation
import UIKit

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var userPhotos: [UserPhoto] = []
    @Published var isLoading = false
    @Published var isUploading = false
    @Published var errorMessage: String?
    
    private let storageService = StorageService()
    
    // MARK: - Fetch User Photos
    func fetchUserPhotos(userId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            userPhotos = try await storageService.getUserPhotos(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Upload Photo
    func uploadPhoto(userId: UUID, image: UIImage, isPrimary: Bool = false) async -> UserPhoto? {
        print("📸 Starting photo upload for user: \(userId)")
        isUploading = true
        defer { isUploading = false }
        
        do {
            let photo = try await storageService.uploadUserPhoto(
                userId: userId,
                image: image,
                isPrimary: isPrimary
            )
            print("✅ Photo uploaded successfully: \(photo.photoUrl)")
            
            // If this is primary, update local state
            if isPrimary {
                for index in userPhotos.indices {
                    userPhotos[index] = UserPhoto(
                        id: userPhotos[index].id,
                        userId: userPhotos[index].userId,
                        photoUrl: userPhotos[index].photoUrl,
                        isPrimary: false,
                        createdAt: userPhotos[index].createdAt
                    )
                }
            }
            
            userPhotos.insert(photo, at: 0)
            return photo
        } catch {
            print("❌ Photo upload failed: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            return nil
        }
    }
    
    // MARK: - Delete Photo
    func deletePhoto(_ photo: UserPhoto) async -> Bool {
        do {
            try await storageService.deleteUserPhoto(photo: photo)
            userPhotos.removeAll { $0.id == photo.id }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    // MARK: - Set Primary Photo
    func setPrimaryPhoto(_ photo: UserPhoto, userId: UUID) async {
        // Re-upload as primary (simpler than updating)
        if let image = await downloadImage(from: photo.photoUrl) {
            _ = await uploadPhoto(userId: userId, image: image, isPrimary: true)
        }
    }
    
    // MARK: - Upload Avatar
    func uploadAvatar(userId: UUID, image: UIImage) async -> String? {
        isUploading = true
        defer { isUploading = false }
        
        do {
            let avatarUrl = try await storageService.uploadAvatar(userId: userId, image: image)
            return avatarUrl
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
    
    // MARK: - Helper
    private func downloadImage(from urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch {
            return nil
        }
    }
}

