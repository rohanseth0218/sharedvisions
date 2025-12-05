import SwiftUI

struct GroupDetailView: View {
    let group: Group
    @ObservedObject var viewModel: GroupViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showInviteCode = false
    @State private var showLeaveConfirmation = false
    
    var body: some View {
        ZStack {
            Color(red: 0.98, green: 0.97, blue: 1.0)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Group header
                    VStack(spacing: 16) {
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
                                Text(String(group.name.prefix(1)).uppercased())
                                    .font(.system(size: 44, weight: .bold))
                                    .foregroundStyle(.white)
                            )
                        
                        Text(group.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("\(viewModel.members.count) members")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Invite section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Invite Partner")
                            .font(.headline)
                        
                        Button {
                            showInviteCode = true
                        } label: {
                            HStack {
                                Image(systemName: "person.badge.plus")
                                    .font(.title3)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Share Invite Code")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Text("Invite your partner to join this group")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .foregroundStyle(.primary)
                            .padding()
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal)
                    
                    // Members section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Members")
                            .font(.headline)
                        
                        VStack(spacing: 0) {
                            ForEach(viewModel.members) { member in
                                MemberRow(member: member)
                                
                                if member.id != viewModel.members.last?.id {
                                    Divider()
                                        .padding(.leading, 60)
                                }
                            }
                        }
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                    
                    // Aesthetic Settings
                    NavigationLink {
                        AestheticSettingsView(group: group, groupViewModel: viewModel)
                    } label: {
                        HStack {
                            Image(systemName: "paintpalette.fill")
                                .font(.title3)
                                .foregroundStyle(Color(red: 0.4, green: 0.2, blue: 0.6))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Aesthetic Settings")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text(group.aestheticProfile != nil ? "Custom style set" : "Use default style")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .foregroundStyle(.primary)
                        .padding()
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                    
                    // Visions count
                    NavigationLink {
                        VisionGridView(groupFilter: group.id)
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                                .font(.title3)
                                .foregroundStyle(Color(red: 0.4, green: 0.2, blue: 0.6))
                            
                            Text("View Group Visions")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .foregroundStyle(.primary)
                        .padding()
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                    
                    // Leave group button
                    Button(role: .destructive) {
                        showLeaveConfirmation = true
                    } label: {
                        Text("Leave Group")
                            .font(.subheadline)
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchMembers(groupId: group.id)
        }
        .sheet(isPresented: $showInviteCode) {
            InviteCodeSheet(group: group, viewModel: viewModel)
                .presentationDetents([.medium])
        }
        .confirmationDialog("Leave Group?", isPresented: $showLeaveConfirmation, titleVisibility: .visible) {
            Button("Leave", role: .destructive) {
                Task {
                    if let userId = authViewModel.currentUser?.id {
                        let success = await viewModel.leaveGroup(groupId: group.id, userId: userId)
                        if success {
                            dismiss()
                        }
                    }
                }
            }
        } message: {
            Text("You'll no longer be able to see or create visions in this group.")
        }
    }
}

struct MemberRow: View {
    let member: GroupMember
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color(red: 0.9, green: 0.9, blue: 0.95))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundStyle(Color(red: 0.4, green: 0.2, blue: 0.6))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(member.user?.fullName ?? "Member")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(member.role.capitalized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
    }
}

struct InviteCodeSheet: View {
    let group: Group
    @ObservedObject var viewModel: GroupViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            // Handle
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 8)
            
            VStack(spacing: 8) {
                Text("Invite Code")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Share this code with your partner")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Code display
            Text(group.inviteCode ?? "------")
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .tracking(8)
                .foregroundStyle(Color(red: 0.4, green: 0.2, blue: 0.6))
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
                .background(Color(red: 0.4, green: 0.2, blue: 0.6).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
            
            // Copy button
            Button {
                if let code = group.inviteCode {
                    UIPasteboard.general.string = code
                }
            } label: {
                Label("Copy Code", systemImage: "doc.on.doc")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(red: 0.4, green: 0.2, blue: 0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
            
            // Share button
            ShareLink(item: "Join my SharedVisions group! Use code: \(group.inviteCode ?? "")") {
                Label("Share", systemImage: "square.and.arrow.up")
                    .font(.headline)
                    .foregroundStyle(Color(red: 0.4, green: 0.2, blue: 0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(red: 0.4, green: 0.2, blue: 0.6).opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        GroupDetailView(
            group: Group(
                id: UUID(),
                name: "Our Dreams",
                inviteCode: "ABC123",
                createdBy: UUID(),
                createdAt: Date()
            ),
            viewModel: GroupViewModel()
        )
        .environmentObject(AuthViewModel())
    }
}

