import Foundation
import Supabase

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
        
        guard let userId = authResponse.user?.id else {
            throw AuthError.signUpFailed
        }
        
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
        guard let authUser = try await supabase.auth.session.user else {
            return nil
        }
        
        let profile: User = try await supabase
            .from(SupabaseService.Table.profiles.rawValue)
            .select()
            .eq("id", value: authUser.id)
            .single()
            .execute()
            .value
        
        return profile
    }
    
    // MARK: - Check Session
    func checkSession() async -> Bool {
        do {
            _ = try await supabase.auth.session
            return true
        } catch {
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

