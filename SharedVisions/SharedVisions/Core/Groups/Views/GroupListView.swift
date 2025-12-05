import SwiftUI

struct GroupListView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = GroupViewModel()
    @State private var showCreateGroup = false
    @State private var showJoinGroup = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.98, green: 0.97, blue: 1.0)
                    .ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.groups.isEmpty {
                    ProgressView()
                } else if viewModel.groups.isEmpty {
                    emptyStateView
                } else {
                    groupList
                }
            }
            .navigationTitle("Groups")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showCreateGroup = true
                        } label: {
                            Label("Create Group", systemImage: "plus.circle")
                        }
                        
                        Button {
                            showJoinGroup = true
                        } label: {
                            Label("Join Group", systemImage: "person.badge.plus")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateGroup) {
                CreateGroupView(viewModel: viewModel)
            }
            .sheet(isPresented: $showJoinGroup) {
                JoinGroupView(viewModel: viewModel)
            }
            .task {
                if let userId = authViewModel.currentUser?.id {
                    await viewModel.fetchGroups(userId: userId)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.2.circle")
                .font(.system(size: 80))
                .foregroundStyle(Color(red: 0.4, green: 0.2, blue: 0.6).opacity(0.5))
            
            VStack(spacing: 8) {
                Text("No Groups Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Create a group with your partner or join an existing one")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                Button {
                    showCreateGroup = true
                } label: {
                    Label("Create Group", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(red: 0.4, green: 0.2, blue: 0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Button {
                    showJoinGroup = true
                } label: {
                    Label("Join with Code", systemImage: "person.badge.plus")
                        .font(.headline)
                        .foregroundStyle(Color(red: 0.4, green: 0.2, blue: 0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(red: 0.4, green: 0.2, blue: 0.6).opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }
    
    private var groupList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.groups) { group in
                    NavigationLink {
                        GroupDetailView(group: group, viewModel: viewModel)
                    } label: {
                        GroupCard(group: group)
                    }
                }
            }
            .padding()
        }
    }
}

struct GroupCard: View {
    let group: Group
    
    var body: some View {
        HStack(spacing: 16) {
            // Group icon
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
                .frame(width: 56, height: 56)
                .overlay(
                    Text(String(group.name.prefix(1)).uppercased())
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                if let memberCount = group.members?.count {
                    Text("\(memberCount) members")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }
}

#Preview {
    GroupListView()
        .environmentObject(AuthViewModel())
}

