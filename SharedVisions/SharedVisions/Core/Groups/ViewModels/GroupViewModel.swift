import Foundation
import Supabase

@MainActor
final class GroupViewModel: ObservableObject {
    @Published var groups: [Group] = []
    @Published var selectedGroup: Group?
    @Published var members: [GroupMember] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase = SupabaseService.shared.client
    
    // MARK: - Fetch User's Groups
    func fetchGroups(userId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Get groups where user is a member
            let memberRecords: [GroupMember] = try await supabase
                .from(SupabaseService.Table.groupMembers.rawValue)
                .select("*, groups(*)")
                .eq("user_id", value: userId)
                .execute()
                .value
            
            // Extract groups from member records
            groups = memberRecords.compactMap { member in
                // Decode the nested group - this is simplified
                // In production, you'd use proper nested decoding
                return nil // Placeholder - implement proper decoding
            }
            
            // Alternative: Fetch groups directly
            let groupIds = memberRecords.map { $0.groupId }
            if !groupIds.isEmpty {
                groups = try await supabase
                    .from(SupabaseService.Table.groups.rawValue)
                    .select()
                    .in("id", values: groupIds)
                    .order("created_at", ascending: false)
                    .execute()
                    .value
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Create Group
    func createGroup(name: String, createdBy: UUID) async -> Group? {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let newGroup = Group(
                id: UUID(),
                name: name,
                inviteCode: Group.generateInviteCode(),
                createdBy: createdBy,
                createdAt: Date()
            )
            
            // Insert group
            try await supabase
                .from(SupabaseService.Table.groups.rawValue)
                .insert(newGroup)
                .execute()
            
            // Add creator as owner
            let member = GroupMember(
                id: UUID(),
                groupId: newGroup.id,
                userId: createdBy,
                role: GroupRole.owner.rawValue,
                joinedAt: Date()
            )
            
            try await supabase
                .from(SupabaseService.Table.groupMembers.rawValue)
                .insert(member)
                .execute()
            
            groups.insert(newGroup, at: 0)
            return newGroup
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
    
    // MARK: - Join Group by Invite Code
    func joinGroup(inviteCode: String, userId: UUID) async -> Bool {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Find group by invite code
            let group: Group = try await supabase
                .from(SupabaseService.Table.groups.rawValue)
                .select()
                .eq("invite_code", value: inviteCode.uppercased())
                .single()
                .execute()
                .value
            
            // Check if already a member
            let existingMember: [GroupMember] = try await supabase
                .from(SupabaseService.Table.groupMembers.rawValue)
                .select()
                .eq("group_id", value: group.id)
                .eq("user_id", value: userId)
                .execute()
                .value
            
            if !existingMember.isEmpty {
                errorMessage = "You're already a member of this group"
                return false
            }
            
            // Add as member
            let member = GroupMember(
                id: UUID(),
                groupId: group.id,
                userId: userId,
                role: GroupRole.member.rawValue,
                joinedAt: Date()
            )
            
            try await supabase
                .from(SupabaseService.Table.groupMembers.rawValue)
                .insert(member)
                .execute()
            
            groups.append(group)
            return true
        } catch {
            errorMessage = "Invalid invite code or group not found"
            return false
        }
    }
    
    // MARK: - Fetch Group Members
    func fetchMembers(groupId: UUID) async {
        do {
            members = try await supabase
                .from(SupabaseService.Table.groupMembers.rawValue)
                .select("*, profiles(*)")
                .eq("group_id", value: groupId)
                .execute()
                .value
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Leave Group
    func leaveGroup(groupId: UUID, userId: UUID) async -> Bool {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await supabase
                .from(SupabaseService.Table.groupMembers.rawValue)
                .delete()
                .eq("group_id", value: groupId)
                .eq("user_id", value: userId)
                .execute()
            
            groups.removeAll { $0.id == groupId }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    // MARK: - Regenerate Invite Code
    func regenerateInviteCode(groupId: UUID) async -> String? {
        do {
            let newCode = Group.generateInviteCode()
            
            try await supabase
                .from(SupabaseService.Table.groups.rawValue)
                .update(["invite_code": newCode])
                .eq("id", value: groupId)
                .execute()
            
            // Update local state
            if let index = groups.firstIndex(where: { $0.id == groupId }) {
                groups[index].inviteCode = newCode
            }
            
            return newCode
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
    
    // MARK: - Update Aesthetic Profile
    func updateAestheticProfile(groupId: UUID, aestheticProfile: AestheticProfile) async {
        do {
            // Encode aesthetic profile to JSON
            let encoder = JSONEncoder()
            let profileData = try encoder.encode(aestheticProfile)
            let profileJSON = try JSONSerialization.jsonObject(with: profileData) as? [String: Any]
            
            try await supabase
                .from(SupabaseService.Table.groups.rawValue)
                .update(["aesthetic_profile": profileJSON])
                .eq("id", value: groupId)
                .execute()
            
            // Update local state
            if let index = groups.firstIndex(where: { $0.id == groupId }) {
                groups[index].aestheticProfile = aestheticProfile
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

