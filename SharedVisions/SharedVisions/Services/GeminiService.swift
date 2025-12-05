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
    func generateImageWithImagen(prompt: String) async throws -> Data {
        // Imagen API endpoint
        let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/imagen-3.0-generate-002:generateImages"
        
        guard let url = URL(string: "\(endpoint)?key=\(Secrets.geminiAPIKey)") else {
            throw GeminiError.invalidEndpoint
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "instances": [
                ["prompt": prompt]
            ],
            "parameters": [
                "sampleCount": 1,
                "aspectRatio": "1:1",
                "safetyFilterLevel": "block_medium_and_above"
            ]
        ]
        
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
    func enhancePrompt(userDescription: String) async throws -> String {
        let systemPrompt = """
        You are a creative assistant helping couples visualize their shared dreams and goals.
        Take the user's description of their vision and enhance it into a detailed image generation prompt.
        Make it warm, positive, and aspirational. Focus on the emotional connection and shared experience.
        Keep the enhanced prompt under 200 words.
        """
        
        let response = try await model.generateContent(
            systemPrompt,
            "User's vision: \(userDescription)"
        )
        
        return response.text ?? userDescription
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

