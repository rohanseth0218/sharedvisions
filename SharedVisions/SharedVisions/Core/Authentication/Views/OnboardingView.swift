import SwiftUI

struct OnboardingView: View {
    @State private var showLogin = false
    @State private var showSignUp = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.4, green: 0.2, blue: 0.6),
                        Color(red: 0.2, green: 0.1, blue: 0.4)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Logo and Title
                    VStack(spacing: 16) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 80))
                            .foregroundStyle(.white)
                            .shadow(color: .white.opacity(0.5), radius: 20)
                        
                        Text("SharedVisions")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Text("Dream Together, Achieve Together")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    // Feature highlights
                    VStack(alignment: .leading, spacing: 20) {
                        FeatureRow(
                            icon: "heart.fill",
                            title: "Connect",
                            description: "Build your shared vision board together"
                        )
                        
                        FeatureRow(
                            icon: "wand.and.stars",
                            title: "Visualize",
                            description: "AI brings your dreams to life"
                        )
                        
                        FeatureRow(
                            icon: "photo.stack",
                            title: "Remember",
                            description: "Keep your aspirations close"
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    // Action buttons
                    VStack(spacing: 16) {
                        Button {
                            showSignUp = true
                        } label: {
                            Text("Get Started")
                                .font(.headline)
                                .foregroundStyle(Color(red: 0.3, green: 0.15, blue: 0.5))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        
                        Button {
                            showLogin = true
                        } label: {
                            Text("I already have an account")
                                .font(.subheadline)
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationDestination(isPresented: $showLogin) {
                LoginView()
            }
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView()
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(.white.opacity(0.2))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }
}

#Preview {
    OnboardingView()
}

