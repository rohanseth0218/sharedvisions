import Foundation
import Supabase

/// Singleton service for Supabase client access
final class SupabaseService {
    static let shared = SupabaseService()
    
    let client: SupabaseClient
    
    private init() {
        guard let url = URL(string: Secrets.supabaseURL) else {
            fatalError("Invalid Supabase URL")
        }
        
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: Secrets.supabaseAnonKey
        )
    }
}

// MARK: - Database Tables
extension SupabaseService {
    enum Table: String {
        case profiles
        case userPhotos = "user_photos"
        case groups
        case groupMembers = "group_members"
        case visions
        case generatedImages = "generated_images"
    }
}

// MARK: - Storage Buckets
extension SupabaseService {
    enum StorageBucket: String {
        case userPhotos = "user-photos"
        case generatedImages = "generated-images"
        case avatars
    }
}

