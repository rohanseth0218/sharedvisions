import Foundation
import Supabase
import UIKit

/// Service for handling file storage operations
actor StorageService {
    private let supabase = SupabaseService.shared.client
    
    // MARK: - Upload User Photo
    func uploadUserPhoto(userId: UUID, image: UIImage, isPrimary: Bool = false) async throws -> UserPhoto {
        print("🔄 StorageService: Converting image to JPEG...")
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("❌ StorageService: Image conversion failed")
            throw StorageError.imageConversionFailed
        }
        print("✅ StorageService: Image converted, size: \(imageData.count) bytes")
        
        let fileName = "\(userId.uuidString)/\(UUID().uuidString).jpg"
        print("🔄 StorageService: Uploading to path: \(fileName)")
        
        // Upload to storage
        do {
            try await supabase.storage
                .from(SupabaseService.StorageBucket.userPhotos.rawValue)
                .upload(
                    path: fileName,
                    file: imageData,
                    options: FileOptions(contentType: "image/jpeg")
                )
            print("✅ StorageService: File uploaded to storage")
        } catch {
            print("❌ StorageService: Storage upload failed: \(error)")
            throw error
        }
        
        // Get public URL
        let publicURL = try supabase.storage
            .from(SupabaseService.StorageBucket.userPhotos.rawValue)
            .getPublicURL(path: fileName)
        
        // If this is primary, unset other primary photos
        if isPrimary {
            try await supabase
                .from(SupabaseService.Table.userPhotos.rawValue)
                .update(["is_primary": false])
                .eq("user_id", value: userId)
                .execute()
        }
        
        // Create database record
        let photo = UserPhoto(
            id: UUID(),
            userId: userId,
            photoUrl: publicURL.absoluteString,
            isPrimary: isPrimary,
            createdAt: Date()
        )
        
        try await supabase
            .from(SupabaseService.Table.userPhotos.rawValue)
            .insert(photo)
            .execute()
        
        return photo
    }
    
    // MARK: - Get User Photos
    func getUserPhotos(userId: UUID) async throws -> [UserPhoto] {
        let photos: [UserPhoto] = try await supabase
            .from(SupabaseService.Table.userPhotos.rawValue)
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return photos
    }
    
    // MARK: - Delete User Photo
    func deleteUserPhoto(photo: UserPhoto) async throws {
        // Extract file path from URL
        if let url = URL(string: photo.photoUrl),
           let pathStart = url.path.range(of: "/user-photos/") {
            let filePath = String(url.path[pathStart.upperBound...])
            
            try await supabase.storage
                .from(SupabaseService.StorageBucket.userPhotos.rawValue)
                .remove(paths: [filePath])
        }
        
        // Delete database record
        try await supabase
            .from(SupabaseService.Table.userPhotos.rawValue)
            .delete()
            .eq("id", value: photo.id)
            .execute()
    }
    
    // MARK: - Upload Generated Image
    func uploadGeneratedImage(visionId: UUID, imageData: Data, prompt: String) async throws -> GeneratedImage {
        let fileName = "\(visionId.uuidString)/\(UUID().uuidString).png"
        
        // Upload to storage
        try await supabase.storage
            .from(SupabaseService.StorageBucket.generatedImages.rawValue)
            .upload(
                path: fileName,
                file: imageData,
                options: FileOptions(contentType: "image/png")
            )
        
        // Get public URL
        let publicURL = try supabase.storage
            .from(SupabaseService.StorageBucket.generatedImages.rawValue)
            .getPublicURL(path: fileName)
        
        // Create database record
        let generatedImage = GeneratedImage(
            id: UUID(),
            visionId: visionId,
            imageUrl: publicURL.absoluteString,
            promptUsed: prompt,
            isFavorite: false,
            createdAt: Date()
        )
        
        try await supabase
            .from(SupabaseService.Table.generatedImages.rawValue)
            .insert(generatedImage)
            .execute()
        
        return generatedImage
    }
    
    // MARK: - Upload Avatar
    func uploadAvatar(userId: UUID, image: UIImage) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw StorageError.imageConversionFailed
        }
        
        let fileName = "\(userId.uuidString).jpg"
        
        // Upload to storage (upsert to replace existing)
        try await supabase.storage
            .from(SupabaseService.StorageBucket.avatars.rawValue)
            .upload(
                path: fileName,
                file: imageData,
                options: FileOptions(contentType: "image/jpeg", upsert: true)
            )
        
        // Get public URL
        let publicURL = try supabase.storage
            .from(SupabaseService.StorageBucket.avatars.rawValue)
            .getPublicURL(path: fileName)
        
        // Update profile
        try await supabase
            .from(SupabaseService.Table.profiles.rawValue)
            .update(["avatar_url": publicURL.absoluteString])
            .eq("id", value: userId)
            .execute()
        
        return publicURL.absoluteString
    }
}

// MARK: - Storage Errors
enum StorageError: LocalizedError {
    case imageConversionFailed
    case uploadFailed
    case downloadFailed
    case deleteFailed
    
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Failed to process image."
        case .uploadFailed:
            return "Failed to upload file."
        case .downloadFailed:
            return "Failed to download file."
        case .deleteFailed:
            return "Failed to delete file."
        }
    }
}

