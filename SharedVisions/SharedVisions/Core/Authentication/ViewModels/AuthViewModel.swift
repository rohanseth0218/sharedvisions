import Foundation
import SwiftUI

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = true
    @Published var currentUser: User?
    @Published var errorMessage: String?
    
    private let authService = AuthService()
    
    // MARK: - Check Session
    func checkSession() async {
        print("🔐 Checking session...")
        isLoading = true
        defer { isLoading = false }
        
        let hasSession = await authService.checkSession()
        print("🔐 Has session: \(hasSession)")
        isAuthenticated = hasSession
        
        if hasSession {
            await loadCurrentUser()
            print("🔐 Current user after load: \(String(describing: currentUser))")
        }
    }
    
    // MARK: - Sign Up
    func signUp(email: String, password: String, fullName: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let user = try await authService.signUp(
                email: email,
                password: password,
                fullName: fullName
            )
            currentUser = user
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Sign In
    func signIn(email: String, password: String) async {
        print("🔐 Signing in: \(email)")
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await authService.signIn(email: email, password: password)
            print("🔐 Sign in successful, loading user...")
            await loadCurrentUser()
            print("🔐 User loaded: \(String(describing: currentUser))")
            isAuthenticated = true
        } catch {
            print("❌ Sign in failed: \(error)")
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Sign Out
    func signOut() async {
        do {
            try await authService.signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Load Current User
    private func loadCurrentUser() async {
        print("🔐 Loading current user from database...")
        do {
            currentUser = try await authService.getCurrentUser()
            print("🔐 Loaded user: \(String(describing: currentUser))")
        } catch {
            print("❌ Failed to load user: \(error)")
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Password Reset
    func sendPasswordReset(email: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await authService.sendPasswordReset(email: email)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

