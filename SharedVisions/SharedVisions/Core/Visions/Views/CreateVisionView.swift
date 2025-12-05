import SwiftUI

struct CreateVisionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @ObservedObject var viewModel: VisionViewModel
    
    @StateObject private var groupViewModel = GroupViewModel()
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedGroup: Group?
    @State private var selectedStyle: ImageStyle = .realistic
    @State private var generateImmediately = true
    @State private var isCreating = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.98, green: 0.97, blue: 1.0)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header illustration
                        VStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 50))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.5, green: 0.3, blue: 0.7),
                                            Color(red: 0.4, green: 0.2, blue: 0.6)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text("Create a Vision")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Describe your shared dream or goal")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 20)
                        
                        // Form
                        VStack(spacing: 20) {
                            // Group selector
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Group")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                                
                                Menu {
                                    ForEach(groupViewModel.groups) { group in
                                        Button {
                                            selectedGroup = group
                                        } label: {
                                            Text(group.name)
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(selectedGroup?.name ?? "Select a group")
                                            .foregroundStyle(selectedGroup == nil ? .secondary : .primary)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding()
                                    .background(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                                }
                            }
                            
                            // Vision title
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Vision Title")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                                
                                TextField("e.g., Beach vacation in Maldives", text: $title)
                                    .textFieldStyle(.plain)
                                    .padding()
                                    .background(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                            }
                            
                            // Description
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description (Optional)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                                
                                TextField("Add more details about your vision...", text: $description, axis: .vertical)
                                    .textFieldStyle(.plain)
                                    .lineLimit(3...6)
                                    .padding()
                                    .background(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                            }
                            
                            // Style selector
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Image Style")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(ImageStyle.allCases, id: \.self) { style in
                                            StyleButton(
                                                style: style,
                                                isSelected: selectedStyle == style
                                            ) {
                                                selectedStyle = style
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Generate toggle
                            Toggle(isOn: $generateImmediately) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Generate immediately")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Text("Create AI image right away")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .tint(Color(red: 0.4, green: 0.2, blue: 0.6))
                            .padding()
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 20)
                    }
                }
                
                // Bottom button
                VStack {
                    Spacer()
                    
                    Button {
                        createVision()
                    } label: {
                        if isCreating {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Create Vision")
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
                    .padding(.bottom, 24)
                    .disabled(!isFormValid || isCreating)
                    .opacity(!isFormValid ? 0.6 : 1)
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
            .task {
                if let userId = authViewModel.currentUser?.id {
                    await groupViewModel.fetchGroups(userId: userId)
                    selectedGroup = groupViewModel.groups.first
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !title.isEmpty && selectedGroup != nil
    }
    
    private func createVision() {
        guard let group = selectedGroup,
              let userId = authViewModel.currentUser?.id else { return }
        
        isCreating = true
        
        Task {
            if let vision = await viewModel.createVision(
                groupId: group.id,
                createdBy: userId,
                title: title,
                description: description.isEmpty ? nil : description
            ) {
                if generateImmediately {
                    await viewModel.generateImage(for: vision, style: selectedStyle)
                }
                dismiss()
            }
            isCreating = false
        }
    }
}

struct StyleButton: View {
    let style: ImageStyle
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : Color(red: 0.4, green: 0.2, blue: 0.6))
                
                Text(style.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .frame(width: 80, height: 80)
            .background(
                isSelected ?
                LinearGradient(
                    colors: [
                        Color(red: 0.5, green: 0.3, blue: 0.7),
                        Color(red: 0.4, green: 0.2, blue: 0.6)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ) :
                LinearGradient(colors: [.white, .white], startPoint: .top, endPoint: .bottom)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(isSelected ? 0.1 : 0.05), radius: 5, y: 2)
        }
    }
    
    private var iconName: String {
        switch style {
        case .realistic: return "camera"
        case .artistic: return "paintbrush"
        case .cinematic: return "film"
        case .dreamy: return "cloud"
        }
    }
}

#Preview {
    CreateVisionView(viewModel: VisionViewModel())
        .environmentObject(AuthViewModel())
}

