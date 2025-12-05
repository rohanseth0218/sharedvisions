import Foundation
import GoogleGenerativeAI
import UIKit

/// Service for AI image generation using Google Gemini
actor GeminiService {
    private let model: GenerativeModel
    private let storageService = StorageService()
    
    init() {
        // Initialize Gemini model for image generation
        // Note: Using gemini-2.0-flash-exp for image generation capabilities
        self.model = GenerativeModel(
            name: "gemini-2.0-flash-exp",
            apiKey: Secrets.geminiAPIKey
        )
    }
    
    // MARK: - Generate Vision Image
    /// Generates an AI image based on the vision description and member photos
    func generateVisionImage(
        vision: Vision,
        memberPhotos: [UserPhoto],
        style: ImageStyle = .realistic
    ) async throws -> Data {
        // Build the prompt
        let prompt = buildPrompt(vision: vision, style: style)
        
        // Download reference photos for context
        var imageParts: [any ThrowingPartsRepresentable] = []
        
        for photo in memberPhotos.prefix(4) { // Limit to 4 photos
            if let imageData = await downloadImage(from: photo.photoUrl) {
                imageParts.append(imageData)
            }
        }
        
        // Generate image with Gemini
        // Note: As of the current API, we use text generation with image context
        // The actual image generation may require Imagen API or future Gemini capabilities
        let response = try await model.generateContent(
            prompt,
            imageParts.isEmpty ? nil : imageParts.first
        )
        
        // For now, we'll create a placeholder response
        // In production, integrate with Google's Imagen API for actual image generation
        guard let text = response.text else {
            throw GeminiError.generationFailed
        }
        
        // TODO: Replace with actual Imagen API call when available
        // For demonstration, we'll return a generated prompt description
        // The actual implementation would return image data from Imagen
        
        throw GeminiError.imageGenerationNotSupported
    }
    
    // MARK: - Generate Image with Imagen
    /// Uses Google's Imagen API to generate images
    /// Note: This requires separate Imagen API access
    /// Can include member photos as reference for personalized generation
    func generateImageWithImagen(
        prompt: String,
        memberPhotos: [UserPhoto] = []
    ) async throws -> Data {
        // Imagen API endpoint
        let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/imagen-3.0-generate-002:generateImages"
        
        guard let url = URL(string: "\(endpoint)?key=\(Secrets.geminiAPIKey)") else {
            throw GeminiError.invalidEndpoint
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Build prompt with member photo context if available
        var finalPrompt = prompt
        if !memberPhotos.isEmpty {
            // Add context about the people in the image
            let memberContext = "This image should feature the specific people whose reference photos are provided. "
            finalPrompt = memberContext + prompt
        }
        
        let body: [String: Any] = [
            "instances": [
                ["prompt": finalPrompt]
            ],
            "parameters": [
                "sampleCount": 1,
                "aspectRatio": "1:1",
                "safetyFilterLevel": "block_medium_and_above"
            ]
        ]
        
        // Note: If Imagen API supports image references, we could add them here:
        // For now, we rely on the prompt description and member photos are used
        // for context in the prompt enhancement phase
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GeminiError.generationFailed
        }
        
        // Parse response and extract image data
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let predictions = json["predictions"] as? [[String: Any]],
              let firstPrediction = predictions.first,
              let imageBase64 = firstPrediction["bytesBase64Encoded"] as? String,
              let imageData = Data(base64Encoded: imageBase64) else {
            throw GeminiError.parsingFailed
        }
        
        return imageData
    }
    
    // MARK: - Build Prompt
    private func buildPrompt(vision: Vision, style: ImageStyle) -> String {
        var promptParts: [String] = []
        
        promptParts.append("Create a beautiful, aspirational photograph showing: \(vision.title)")
        
        if let description = vision.description, !description.isEmpty {
            promptParts.append("Details: \(description)")
        }
        
        promptParts.append("Style: \(style.description)")
        promptParts.append("The image should be warm, inviting, and represent a couple's shared dream or goal.")
        promptParts.append("High quality, professional photography style.")
        
        return promptParts.joined(separator: "\n")
    }
    
    // MARK: - Enhance Prompt
    /// Uses Gemini to enhance a user's vision description into a better image prompt
    /// Includes member names and context for personalized image generation
    func enhancePrompt(
        userDescription: String,
        memberNames: [String: String] = [:] // userId -> name mapping
    ) async throws -> String {
        var systemPrompt = """
        You are a creative assistant helping couples visualize their shared dreams and goals.
        Take the user's description of their vision and enhance it into a detailed image generation prompt.
        Make it warm, positive, and aspirational. Focus on the emotional connection and shared experience.
        Keep the enhanced prompt under 200 words.
        """
        
        // Add member context if available
        if !memberNames.isEmpty {
            let memberList = memberNames.values.joined(separator: ", ")
            systemPrompt += "\n\nImportant: The image should include these specific people: \(memberList). Make sure to represent them accurately in the scene."
        }
        
        let response = try await model.generateContent(
            systemPrompt,
            "User's vision: \(userDescription)"
        )
        
        return response.text ?? userDescription
    }
    
    // MARK: - Parse Prompt for Member Names (AI-Powered)
    /// Uses Gemini to parse user prompt and identify which members should be in the image
    /// Returns mapping of user IDs to their names as mentioned in the prompt
    func parsePromptForMembers(
        prompt: String,
        availableMembers: [GroupMember],
        currentUserId: UUID,
        currentUserName: String
    ) async throws -> [UUID: String] {
        // Build member list for AI context
        var memberContext = "Available group members:\n"
        for member in availableMembers {
            if let name = member.user?.fullName {
                let firstName = name.components(separatedBy: " ").first ?? name
                memberContext += "- \(firstName) (ID: \(member.userId.uuidString))\n"
            }
        }
        memberContext += "\nCurrent user: \(currentUserName) (ID: \(currentUserId.uuidString))"
        
        // Create structured prompt for AI parsing
        let parsingPrompt = """
        You are parsing a vision description to identify which people should appear in an AI-generated image.
        
        \(memberContext)
        
        User's vision description: "\(prompt)"
        
        Analyze the description and identify:
        1. Does it mention "me", "I", or the current user? (ID: \(currentUserId.uuidString))
        2. Does it mention any other group members by name?
        
        Return a JSON object with this structure:
        {
            "mentioned_members": [
                {
                    "user_id": "uuid-string",
                    "name_in_prompt": "how they're referred to in the prompt"
                }
            ]
        }
        
        Only include members explicitly mentioned. If the description says "me and Izzy", include both the current user and Izzy.
        If it just says "a beach vacation" without mentioning people, return an empty array (meaning all members).
        """
        
        let response = try await model.generateContent(parsingPrompt)
        
        guard let responseText = response.text else {
            // Fallback to simple parsing if AI fails
            return fallbackParseMembers(
                from: prompt,
                availableMembers: availableMembers,
                currentUserId: currentUserId
            )
        }
        
        // Parse JSON response
        return try parseMemberJSON(
            jsonString: responseText,
            availableMembers: availableMembers,
            currentUserId: currentUserId
        )
    }
    
    // MARK: - Parse Member JSON Response
    private func parseMemberJSON(
        jsonString: String,
        availableMembers: [GroupMember],
        currentUserId: UUID
    ) throws -> [UUID: String] {
        // Extract JSON from markdown code blocks if present
        var cleanJSON = jsonString
        if let jsonRange = cleanJSON.range(of: "```json") {
            cleanJSON = String(cleanJSON[jsonRange.upperBound...])
        }
        if let jsonRange = cleanJSON.range(of: "```") {
            cleanJSON = String(cleanJSON[..<jsonRange.lowerBound])
        }
        cleanJSON = cleanJSON.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let jsonData = cleanJSON.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let mentionedMembers = json["mentioned_members"] as? [[String: Any]] else {
            // Fallback if JSON parsing fails
            return fallbackParseMembers(
                from: cleanJSON,
                availableMembers: availableMembers,
                currentUserId: currentUserId
            )
        }
        
        var memberMap: [UUID: String] = [:]
        
        for memberData in mentionedMembers {
            guard let userIdString = memberData["user_id"] as? String,
                  let userId = UUID(uuidString: userIdString),
                  let nameInPrompt = memberData["name_in_prompt"] as? String else {
                continue
            }
            
            // Verify this user ID exists in available members
            if availableMembers.contains(where: { $0.userId == userId }) || userId == currentUserId {
                memberMap[userId] = nameInPrompt
            }
        }
        
        return memberMap
    }
    
    // MARK: - Fallback Member Parsing
    /// Simple fallback if AI parsing fails - uses basic string matching
    private func fallbackParseMembers(
        from description: String,
        availableMembers: [GroupMember],
        currentUserId: UUID
    ) -> [UUID: String] {
        var foundMembers: [UUID: String] = [:]
        let lowerDescription = description.lowercased()
        
        // Always include current user if "me" or "I" is mentioned
        if lowerDescription.contains("me") || lowerDescription.contains(" i ") || lowerDescription.hasPrefix("i ") {
            foundMembers[currentUserId] = "me"
        }
        
        // Check for each member's name in description
        for member in availableMembers {
            if let name = member.user?.fullName {
                let firstName = name.components(separatedBy: " ").first?.lowercased() ?? ""
                let fullNameLower = name.lowercased()
                
                // Check if name appears in description
                if lowerDescription.contains(firstName) || lowerDescription.contains(fullNameLower) {
                    foundMembers[member.userId] = firstName.capitalized
                }
            }
        }
        
        return foundMembers
    }
    
    // MARK: - Download Image Helper
    private func downloadImage(from urlString: String) async -> Data? {
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return data
        } catch {
            return nil
        }
    }
}

// MARK: - Gemini Errors
enum GeminiError: LocalizedError {
    case generationFailed
    case parsingFailed
    case invalidEndpoint
    case imageGenerationNotSupported
    case rateLimitExceeded
    
    var errorDescription: String? {
        switch self {
        case .generationFailed:
            return "Failed to generate image. Please try again."
        case .parsingFailed:
            return "Failed to process the generated image."
        case .invalidEndpoint:
            return "Invalid API endpoint."
        case .imageGenerationNotSupported:
            return "Image generation requires Imagen API access."
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please wait a moment and try again."
        }
    }
}

