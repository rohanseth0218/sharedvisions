import Foundation
import Supabase
import Auth

/// Service for handling authentication operations
actor AuthService {
    private let supabase = SupabaseService.shared.client
    
    // MARK: - Sign Up
    func signUp(email: String, password: String, fullName: String) async throws -> User {
        // Create auth user
        let authResponse = try await supabase.auth.signUp(
            email: email,
            password: password,
            data: ["full_name": .string(fullName)]
        )
        
        let userId = authResponse.user.id
        
        // Create profile record
        let profile = User(
            id: userId,
            username: nil,
            fullName: fullName,
            avatarUrl: nil,
            createdAt: Date()
        )
        
        try await supabase
            .from(SupabaseService.Table.profiles.rawValue)
            .insert(profile)
            .execute()
        
        return profile
    }
    
    // MARK: - Sign In
    func signIn(email: String, password: String) async throws {
        try await supabase.auth.signIn(
            email: email,
            password: password
        )
    }
    
    // MARK: - Sign Out
    func signOut() async throws {
        try await supabase.auth.signOut()
    }
    
    // MARK: - Get Current User
    func getCurrentUser() async throws -> User? {
        // Get current session - throws if no session exists
        let session: Session
        do {
            session = try await supabase.auth.session
            print("🔐 AuthService: Got session for user: \(session.user.id)")
        } catch {
            print("❌ AuthService: No session found")
            return nil
        }
        
        let authUser = session.user
        
        // Try to get profile, but if it fails or is cancelled, create a basic user from session
        do {
            let profile: User = try await supabase
                .from(SupabaseService.Table.profiles.rawValue)
                .select()
                .eq("id", value: authUser.id)
                .single()
                .execute()
                .value
            
            print("✅ AuthService: Found profile: \(profile)")
            return profile
        } catch {
            print("❌ AuthService: Profile query failed: \(error)")
            
            // Return a user based on session data (even if profile doesn't exist in DB)
            let fallbackUser = User(
                id: authUser.id,
                username: nil,
                fullName: authUser.userMetadata["full_name"] as? String ?? authUser.email ?? "User",
                avatarUrl: nil,
                createdAt: Date()
            )
            print("💡 AuthService: Using fallback user from session: \(fallbackUser.id)")
            
            // Try to create profile in background (don't await, don't block)
            Task.detached {
                do {
                    try await self.supabase
                        .from(SupabaseService.Table.profiles.rawValue)
                        .upsert(fallbackUser)
                        .execute()
                    print("✅ AuthService: Created/updated profile in background")
                } catch {
                    print("⚠️ AuthService: Background profile creation failed: \(error)")
                }
            }
            
            return fallbackUser
        }
    }
    
    // MARK: - Check Session
    func checkSession() async -> Bool {
        do {
            let session = try await supabase.auth.session
            print("🔐 AuthService.checkSession: Valid session for \(session.user.id)")
            return true
        } catch {
            print("🔐 AuthService.checkSession: No valid session - \(error)")
            return false
        }
    }
    
    // MARK: - Update Profile
    func updateProfile(userId: UUID, username: String?, fullName: String?) async throws {
        var updates: [String: String] = [:]
        
        if let username = username {
            updates["username"] = username
        }
        if let fullName = fullName {
            updates["full_name"] = fullName
        }
        
        try await supabase
            .from(SupabaseService.Table.profiles.rawValue)
            .update(updates)
            .eq("id", value: userId)
            .execute()
    }
    
    // MARK: - Password Reset
    func sendPasswordReset(email: String) async throws {
        try await supabase.auth.resetPasswordForEmail(email)
    }
}

// MARK: - Auth Errors
enum AuthError: LocalizedError {
    case signUpFailed
    case signInFailed
    case notAuthenticated
    case profileNotFound
    
    var errorDescription: String? {
        switch self {
        case .signUpFailed:
            return "Failed to create account. Please try again."
        case .signInFailed:
            return "Failed to sign in. Please check your credentials."
        case .notAuthenticated:
            return "You are not signed in."
        case .profileNotFound:
            return "Profile not found."
        }
    }
}

