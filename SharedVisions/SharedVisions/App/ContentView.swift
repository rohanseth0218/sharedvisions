import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        ZStack {
            if authViewModel.isLoading {
                LoadingView()
            } else if authViewModel.isAuthenticated {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .task {
            await authViewModel.checkSession()
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            VisionFeedView()
                .tabItem {
                    Label("Feed", systemImage: "rectangle.stack")
                }
            
            VisionGridView()
                .tabItem {
                    Label("Gallery", systemImage: "square.grid.2x2")
                }
            
            GroupListView()
                .tabItem {
                    Label("Groups", systemImage: "person.2")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
        }
        .tint(.purple)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}

