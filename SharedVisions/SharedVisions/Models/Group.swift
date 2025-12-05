import Foundation

struct Group: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var inviteCode: String?
    let createdBy: UUID?
    let createdAt: Date?
    
    // Relationships (optional, loaded separately)
    var members: [GroupMember]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case inviteCode = "invite_code"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case members
    }
    
    // Generate a random invite code
    static func generateInviteCode() -> String {
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).map { _ in characters.randomElement()! })
    }
}

struct GroupMember: Codable, Identifiable, Hashable {
    let id: UUID
    let groupId: UUID
    let userId: UUID
    var role: String
    let joinedAt: Date?
    
    // Relationship
    var user: User?
    
    enum CodingKeys: String, CodingKey {
        case id
        case groupId = "group_id"
        case userId = "user_id"
        case role
        case joinedAt = "joined_at"
        case user
    }
}

enum GroupRole: String, Codable {
    case owner = "owner"
    case admin = "admin"
    case member = "member"
}

