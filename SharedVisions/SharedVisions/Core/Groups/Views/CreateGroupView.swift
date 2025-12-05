import SwiftUI

struct CreateGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @ObservedObject var viewModel: GroupViewModel
    
    @State private var groupName = ""
    @State private var isCreating = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.98, green: 0.97, blue: 1.0)
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    // Icon
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.5, green: 0.3, blue: 0.7),
                                    Color(red: 0.4, green: 0.2, blue: 0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.white)
                        )
                        .padding(.top, 40)
                    
                    VStack(spacing: 8) {
                        Text("Create a Group")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Start building shared visions with your partner")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Group name input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Group Name")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        
                        TextField("e.g., Our Dreams", text: $groupName)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    // Create button
                    Button {
                        Task {
                            isCreating = true
                            if let userId = authViewModel.currentUser?.id {
                                if let _ = await viewModel.createGroup(name: groupName, createdBy: userId) {
                                    dismiss()
                                }
                            }
                            isCreating = false
                        }
                    } label: {
                        if isCreating {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Create Group")
                                .font(.headline)
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.5, green: 0.3, blue: 0.7),
                                Color(red: 0.4, green: 0.2, blue: 0.6)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 24)
                    .disabled(groupName.isEmpty || isCreating)
                    .opacity(groupName.isEmpty ? 0.6 : 1)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct JoinGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @ObservedObject var viewModel: GroupViewModel
    
    @State private var inviteCode = ""
    @State private var isJoining = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.98, green: 0.97, blue: 1.0)
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    // Icon
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.5, green: 0.3, blue: 0.7),
                                    Color(red: 0.4, green: 0.2, blue: 0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 40))
                                .foregroundStyle(.white)
                        )
                        .padding(.top, 40)
                    
                    VStack(spacing: 8) {
                        Text("Join a Group")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Enter the invite code shared by your partner")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Invite code input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Invite Code")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        
                        TextField("ABC123", text: $inviteCode)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .font(.system(.title3, design: .monospaced))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)
                    
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    }
                    
                    Spacer()
                    
                    // Join button
                    Button {
                        Task {
                            isJoining = true
                            if let userId = authViewModel.currentUser?.id {
                                let success = await viewModel.joinGroup(inviteCode: inviteCode, userId: userId)
                                if success {
                                    dismiss()
                                }
                            }
                            isJoining = false
                        }
                    } label: {
                        if isJoining {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Join Group")
                                .font(.headline)
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.5, green: 0.3, blue: 0.7),
                                Color(red: 0.4, green: 0.2, blue: 0.6)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 24)
                    .disabled(inviteCode.count < 6 || isJoining)
                    .opacity(inviteCode.count < 6 ? 0.6 : 1)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CreateGroupView(viewModel: GroupViewModel())
        .environmentObject(AuthViewModel())
}

