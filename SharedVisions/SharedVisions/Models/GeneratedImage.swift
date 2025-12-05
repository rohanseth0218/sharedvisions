import Foundation

struct GeneratedImage: Codable, Identifiable, Hashable {
    let id: UUID
    let visionId: UUID
    let imageUrl: String
    var promptUsed: String?
    var isFavorite: Bool
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case visionId = "vision_id"
        case imageUrl = "image_url"
        case promptUsed = "prompt_used"
        case isFavorite = "is_favorite"
        case createdAt = "created_at"
    }
}

// Request model for generating images
struct ImageGenerationRequest {
    let vision: Vision
    let memberPhotos: [UserPhoto]
    let style: ImageStyle
    
    var prompt: String {
        // Build a prompt based on the vision and style
        var promptParts: [String] = []
        
        promptParts.append("Create a realistic photograph showing")
        promptParts.append(vision.title)
        
        if let description = vision.description, !description.isEmpty {
            promptParts.append("with the following details: \(description)")
        }
        
        promptParts.append("Style: \(style.description)")
        promptParts.append("Make it look natural, warm, and aspirational.")
        
        return promptParts.joined(separator: ". ")
    }
}

enum ImageStyle: String, CaseIterable {
    case realistic = "realistic"
    case artistic = "artistic"
    case cinematic = "cinematic"
    case dreamy = "dreamy"
    
    var description: String {
        switch self {
        case .realistic: return "Photorealistic, natural lighting, candid moment"
        case .artistic: return "Artistic interpretation, painterly style"
        case .cinematic: return "Cinematic look, dramatic lighting, movie-like"
        case .dreamy: return "Soft focus, ethereal, dreamlike quality"
        }
    }
    
    var displayName: String {
        switch self {
        case .realistic: return "Realistic"
        case .artistic: return "Artistic"
        case .cinematic: return "Cinematic"
        case .dreamy: return "Dreamy"
        }
    }
}

