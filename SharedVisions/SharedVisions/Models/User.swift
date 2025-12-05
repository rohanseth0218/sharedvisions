import Foundation

struct User: Codable, Identifiable, Hashable {
    let id: UUID
    var username: String?
    var fullName: String?
    var avatarUrl: String?
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
        case createdAt = "created_at"
    }
}

struct UserPhoto: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let photoUrl: String
    var isPrimary: Bool
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case photoUrl = "photo_url"
        case isPrimary = "is_primary"
        case createdAt = "created_at"
    }
}

