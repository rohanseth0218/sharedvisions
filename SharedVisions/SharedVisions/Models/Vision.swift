import Foundation

struct Vision: Codable, Identifiable, Hashable {
    let id: UUID
    let groupId: UUID
    let createdBy: UUID?
    var title: String
    var description: String?
    var targetMembers: [UUID]
    var status: VisionStatus
    let createdAt: Date?
    
    // Relationships
    var generatedImages: [GeneratedImage]?
    var group: Group?
    var creator: User?
    
    enum CodingKeys: String, CodingKey {
        case id
        case groupId = "group_id"
        case createdBy = "created_by"
        case title
        case description
        case targetMembers = "target_members"
        case status
        case createdAt = "created_at"
        case generatedImages = "generated_images"
        case group
        case creator
    }
    
    // Check if vision is for all members (empty target means all)
    var isForAllMembers: Bool {
        targetMembers.isEmpty
    }
}

enum VisionStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case generating = "generating"
    case completed = "completed"
    case failed = "failed"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .generating: return "Generating..."
        case .completed: return "Completed"
        case .failed: return "Failed"
        }
    }
    
    var iconName: String {
        switch self {
        case .pending: return "clock"
        case .generating: return "sparkles"
        case .completed: return "checkmark.circle"
        case .failed: return "exclamationmark.triangle"
        }
    }
}

