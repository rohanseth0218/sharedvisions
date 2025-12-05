import Foundation
import Supabase

@MainActor
final class VisionViewModel: ObservableObject {
    @Published var visions: [Vision] = []
    @Published var selectedVision: Vision?
    @Published var isLoading = false
    @Published var isGenerating = false
    @Published var errorMessage: String?
    
    private let supabase = SupabaseService.shared.client
    private let geminiService = GeminiService()
    private let storageService = StorageService()
    
    // MARK: - Fetch Visions
    func fetchVisions(groupId: UUID? = nil) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            var query = supabase
                .from(SupabaseService.Table.visions.rawValue)
                .select("*, generated_images(*)")
            
            if let groupId = groupId {
                query = query.eq("group_id", value: groupId)
            }
            
            visions = try await query
                .order("created_at", ascending: false)
                .execute()
                .value
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Fetch Visions for User's Groups
    func fetchVisionsForUser(userId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // First get user's groups
            let memberRecords: [GroupMember] = try await supabase
                .from(SupabaseService.Table.groupMembers.rawValue)
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value
            
            let groupIds = memberRecords.map { $0.groupId }
            
            if groupIds.isEmpty {
                visions = []
                return
            }
            
            // Then fetch visions for those groups
            visions = try await supabase
                .from(SupabaseService.Table.visions.rawValue)
                .select("*, generated_images(*)")
                .in("group_id", values: groupIds)
                .order("created_at", ascending: false)
                .execute()
                .value
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Create Vision
    func createVision(
        groupId: UUID,
        createdBy: UUID,
        title: String,
        description: String?,
        targetMembers: [UUID] = []
    ) async -> Vision? {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let vision = Vision(
                id: UUID(),
                groupId: groupId,
                createdBy: createdBy,
                title: title,
                description: description,
                targetMembers: targetMembers,
                status: .pending,
                createdAt: Date()
            )
            
            try await supabase
                .from(SupabaseService.Table.visions.rawValue)
                .insert(vision)
                .execute()
            
            visions.insert(vision, at: 0)
            return vision
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
    
    // MARK: - Generate Image for Vision
    func generateImage(for vision: Vision, style: ImageStyle = .realistic) async -> GeneratedImage? {
        isGenerating = true
        defer { isGenerating = false }
        
        do {
            // Update vision status to generating
            try await updateVisionStatus(vision.id, status: .generating)
            
            // Get member photos for the vision
            let memberPhotos = try await fetchMemberPhotos(for: vision)
            
            // Build the prompt
            let enhancedPrompt = try await geminiService.enhancePrompt(userDescription: vision.title + (vision.description ?? ""))
            
            // Generate image using Imagen API
            let imageData = try await geminiService.generateImageWithImagen(prompt: enhancedPrompt)
            
            // Upload to storage
            let generatedImage = try await storageService.uploadGeneratedImage(
                visionId: vision.id,
                imageData: imageData,
                prompt: enhancedPrompt
            )
            
            // Update vision status to completed
            try await updateVisionStatus(vision.id, status: .completed)
            
            // Update local state
            if let index = visions.firstIndex(where: { $0.id == vision.id }) {
                var updatedVision = visions[index]
                updatedVision.generatedImages = (updatedVision.generatedImages ?? []) + [generatedImage]
                updatedVision.status = .completed
                visions[index] = updatedVision
            }
            
            return generatedImage
        } catch {
            // Update vision status to failed
            try? await updateVisionStatus(vision.id, status: .failed)
            errorMessage = error.localizedDescription
            return nil
        }
    }
    
    // MARK: - Update Vision Status
    private func updateVisionStatus(_ visionId: UUID, status: VisionStatus) async throws {
        try await supabase
            .from(SupabaseService.Table.visions.rawValue)
            .update(["status": status.rawValue])
            .eq("id", value: visionId)
            .execute()
    }
    
    // MARK: - Fetch Member Photos
    private func fetchMemberPhotos(for vision: Vision) async throws -> [UserPhoto] {
        // Get group members
        let members: [GroupMember] = try await supabase
            .from(SupabaseService.Table.groupMembers.rawValue)
            .select()
            .eq("group_id", value: vision.groupId)
            .execute()
            .value
        
        // Filter to target members if specified
        let targetUserIds: [UUID]
        if vision.targetMembers.isEmpty {
            targetUserIds = members.map { $0.userId }
        } else {
            targetUserIds = vision.targetMembers
        }
        
        // Get photos for target members
        let photos: [UserPhoto] = try await supabase
            .from(SupabaseService.Table.userPhotos.rawValue)
            .select()
            .in("user_id", values: targetUserIds)
            .execute()
            .value
        
        return photos
    }
    
    // MARK: - Toggle Favorite
    func toggleFavorite(image: GeneratedImage) async {
        do {
            try await supabase
                .from(SupabaseService.Table.generatedImages.rawValue)
                .update(["is_favorite": !image.isFavorite])
                .eq("id", value: image.id)
                .execute()
            
            // Update local state
            for (visionIndex, vision) in visions.enumerated() {
                if let images = vision.generatedImages,
                   let imageIndex = images.firstIndex(where: { $0.id == image.id }) {
                    var updatedImages = images
                    var updatedImage = updatedImages[imageIndex]
                    updatedImage = GeneratedImage(
                        id: updatedImage.id,
                        visionId: updatedImage.visionId,
                        imageUrl: updatedImage.imageUrl,
                        promptUsed: updatedImage.promptUsed,
                        isFavorite: !updatedImage.isFavorite,
                        createdAt: updatedImage.createdAt
                    )
                    updatedImages[imageIndex] = updatedImage
                    visions[visionIndex].generatedImages = updatedImages
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Delete Vision
    func deleteVision(_ visionId: UUID) async -> Bool {
        do {
            try await supabase
                .from(SupabaseService.Table.visions.rawValue)
                .delete()
                .eq("id", value: visionId)
                .execute()
            
            visions.removeAll { $0.id == visionId }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}

