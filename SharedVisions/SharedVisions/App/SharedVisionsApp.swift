import SwiftUI
import Supabase

@main
struct SharedVisionsApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    init() {
        // Initialize Supabase client on app launch
        _ = SupabaseService.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
        }
    }
}

