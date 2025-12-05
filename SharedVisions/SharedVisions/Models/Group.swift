import Foundation

struct Group: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var inviteCode: String?
    let createdBy: UUID?
    let createdAt: Date?
    var aestheticProfile: AestheticProfile? // Group's visual style preferences
    
    // Relationships (optional, loaded separately)
    var members: [GroupMember]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case inviteCode = "invite_code"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case aestheticProfile = "aesthetic_profile"
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

// MARK: - Aesthetic Profile
/// Defines the visual style and aesthetic preferences for a group's images
struct AestheticProfile: Codable, Hashable {
    var baseStyle: ImageStyle = .realistic
    var colorPalette: String? // e.g., "warm tones", "cool blues", "vibrant colors"
    var mood: String? // e.g., "romantic", "adventurous", "peaceful", "energetic"
    var lighting: String? // e.g., "golden hour", "soft natural", "dramatic"
    var composition: String? // e.g., "candid", "posed", "cinematic"
    var overallVibe: String? // Custom description of the aesthetic
    
    enum CodingKeys: String, CodingKey {
        case baseStyle = "base_style"
        case colorPalette = "color_palette"
        case mood
        case lighting
        case composition
        case overallVibe = "overall_vibe"
    }
    
    /// Generates a consistent prompt suffix for all images
    func promptSuffix() -> String {
        var parts: [String] = []
        
        if let vibe = overallVibe, !vibe.isEmpty {
            parts.append("Overall aesthetic: \(vibe)")
        } else {
            // Build from components
            parts.append("Style: \(baseStyle.description)")
            
            if let color = colorPalette, !color.isEmpty {
                parts.append("Color palette: \(color)")
            }
            
            if let moodValue = mood, !moodValue.isEmpty {
                parts.append("Mood: \(moodValue)")
            }
            
            if let lightingValue = lighting, !lightingValue.isEmpty {
                parts.append("Lighting: \(lightingValue)")
            }
            
            if let comp = composition, !comp.isEmpty {
                parts.append("Composition: \(comp)")
            }
        }
        
        parts.append("Maintain visual consistency with previous images from this group.")
        
        return parts.joined(separator: ". ")
    }
    
    /// Default aesthetic profile
    static let `default` = AestheticProfile(
        baseStyle: .realistic,
        colorPalette: "warm, inviting tones",
        mood: "aspirational and romantic",
        lighting: "soft natural lighting",
        composition: "candid, authentic moments"
    )
}

