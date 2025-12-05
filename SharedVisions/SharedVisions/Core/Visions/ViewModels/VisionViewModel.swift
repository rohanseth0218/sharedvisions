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
        targetMembers: [UUID] = [] // Empty = all members, otherwise specific members
    ) async -> Vision? {
        print("📝 VisionViewModel.createVision called")
        print("📝 Title: \(title), GroupID: \(groupId)")
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
            
            print("📝 Inserting vision into Supabase...")
            try await supabase
                .from(SupabaseService.Table.visions.rawValue)
                .insert(vision)
                .execute()
            
            print("✅ Vision inserted successfully: \(vision.id)")
            visions.insert(vision, at: 0)
            return vision
        } catch {
            print("❌ Vision creation failed: \(error)")
            errorMessage = error.localizedDescription
            return nil
        }
    }
    
    // MARK: - Generate Image for Vision
    func generateImage(for vision: Vision, style: ImageStyle = .realistic) async -> GeneratedImage? {
        print("🖼️ VisionViewModel: Starting image generation for vision: \(vision.title)")
        isGenerating = true
        defer { isGenerating = false }
        
        do {
            // Update vision status to generating
            print("🖼️ VisionViewModel: Updating status to generating...")
            try await updateVisionStatus(vision.id, status: .generating)
            
            // Get group members with user info
            let members: [GroupMember] = try await supabase
                .from(SupabaseService.Table.groupMembers.rawValue)
                .select("*, profiles(*)")
                .eq("group_id", value: vision.groupId)
                .execute()
                .value
            
            // Parse prompt to identify which members should be included (AI-powered)
            let currentUserId = vision.createdBy ?? UUID()
            let currentUser: User? = try? await supabase
                .from(SupabaseService.Table.profiles.rawValue)
                .select()
                .eq("id", value: currentUserId)
                .single()
                .execute()
                .value
            
            let currentUserName = currentUser?.fullName ?? "me"
            let fullPrompt = vision.title + (vision.description.map { " " + $0 } ?? "")
            
            // Use AI to parse which members are mentioned in the prompt
            let mentionedMembers = try await geminiService.parsePromptForMembers(
                prompt: fullPrompt,
                availableMembers: members,
                currentUserId: currentUserId,
                currentUserName: currentUserName
            )
            
            // Determine target user IDs: prioritize manual selection, then AI parsing, then all members
            let finalTargetUserIds: [UUID]
            if !vision.targetMembers.isEmpty {
                // User explicitly selected members - use those (highest priority)
                print("👥 Using manually selected members: \(vision.targetMembers.count)")
                finalTargetUserIds = vision.targetMembers
            } else if !mentionedMembers.isEmpty {
                // AI parsed members from description - use those
                print("🤖 Using AI-parsed members from description: \(mentionedMembers.keys.count)")
                finalTargetUserIds = Array(mentionedMembers.keys)
            } else {
                // Default to all members
                print("👥 Using all group members (default)")
                finalTargetUserIds = members.map { $0.userId }
            }
            
            // Get member photos for the identified members
            let memberPhotos = try await fetchMemberPhotos(for: vision, targetUserIds: finalTargetUserIds)
            
            // Build member name mapping for prompt enhancement
            let targetMembers = members.filter { finalTargetUserIds.contains($0.userId) }
            let memberNameMap = buildMemberNameMap(
                members: targetMembers,
                currentUserId: currentUserId
            )
            
            // Get group aesthetic profile for consistency
            let group: Group = try await supabase
                .from(SupabaseService.Table.groups.rawValue)
                .select()
                .eq("id", value: vision.groupId)
                .single()
                .execute()
                .value
            
            // Enhance the prompt with member context and aesthetic profile
            let enhancedPrompt = try await geminiService.enhancePrompt(
                userDescription: fullPrompt,
                memberNames: memberNameMap,
                aestheticProfile: group.aestheticProfile ?? AestheticProfile.default
            )
            
            // Generate image using Imagen API with member photos as context
            let imageData = try await geminiService.generateImageWithImagen(
                prompt: enhancedPrompt,
                memberPhotos: memberPhotos
            )
            
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
            
            print("✅ VisionViewModel: Image generation complete!")
            return generatedImage
        } catch {
            // Update vision status to failed
            print("❌ VisionViewModel: Image generation failed: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
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
    private func fetchMemberPhotos(for vision: Vision, targetUserIds: [UUID]) async throws -> [UserPhoto] {
        // Get photos for target members (prioritize primary photos)
        let photos: [UserPhoto] = try await supabase
            .from(SupabaseService.Table.userPhotos.rawValue)
            .select()
            .in("user_id", values: targetUserIds)
            .order("is_primary", ascending: false)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return photos
    }
    
    // MARK: - Build Member Name Map
    /// Creates a mapping of user IDs to their names for prompt generation
    private func buildMemberNameMap(members: [GroupMember], currentUserId: UUID) -> [String: String] {
        var nameMap: [String: String] = [:]
        
        for member in members {
            if let name = member.user?.fullName {
                // Use first name for more natural prompts
                let firstName = name.components(separatedBy: " ").first ?? name
                nameMap[member.userId.uuidString] = firstName
            } else if let username = member.user?.username {
                nameMap[member.userId.uuidString] = username
            }
        }
        
        return nameMap
    }
    
    // MARK: - Enhance Description with Member Names
    /// Replaces "me" and "I" with actual names in the description
    private func enhanceDescriptionWithMemberNames(
        description: String,
        memberNameMap: [UUID: String],
        currentUserId: UUID
    ) -> String {
        var enhanced = description
        
        // Replace "me" with actual name if current user is in the map
        if let currentUserName = memberNameMap[currentUserId] {
            // Replace "me" (word boundary) with name
            enhanced = enhanced.replacingOccurrences(
                of: "\\bme\\b",
                with: currentUserName,
                options: [.regularExpression, .caseInsensitive]
            )
            // Replace "I" at start of sentence
            enhanced = enhanced.replacingOccurrences(
                of: "^I ",
                with: "\(currentUserName) ",
                options: [.regularExpression, .caseInsensitive]
            )
        }
        
        return enhanced
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

