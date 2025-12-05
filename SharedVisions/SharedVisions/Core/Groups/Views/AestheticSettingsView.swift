import SwiftUI

struct AestheticSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var groupViewModel: GroupViewModel
    let group: Group
    @State private var aestheticProfile: AestheticProfile
    @State private var isSaving = false
    
    init(group: Group, groupViewModel: GroupViewModel) {
        self.group = group
        self.groupViewModel = groupViewModel
        _aestheticProfile = State(initialValue: group.aestheticProfile ?? AestheticProfile.default)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.98, green: 0.97, blue: 1.0)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "paintpalette.fill")
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
                            
                            Text("Group Aesthetic")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Set the visual style for all images in this group")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        // Base Style
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Base Style")
                                .font(.headline)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(ImageStyle.allCases, id: \.self) { style in
                                        StyleButton(
                                            style: style,
                                            isSelected: aestheticProfile.baseStyle == style
                                        ) {
                                            aestheticProfile.baseStyle = style
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        // Color Palette
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Color Palette")
                                .font(.headline)
                            
                            TextField("e.g., warm tones, cool blues, vibrant colors", text: Binding(
                                get: { aestheticProfile.colorPalette ?? "" },
                                set: { aestheticProfile.colorPalette = $0.isEmpty ? nil : $0 }
                            ))
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color(white: 0.95))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding()
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        // Mood
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Mood")
                                .font(.headline)
                            
                            TextField("e.g., romantic, adventurous, peaceful, energetic", text: Binding(
                                get: { aestheticProfile.mood ?? "" },
                                set: { aestheticProfile.mood = $0.isEmpty ? nil : $0 }
                            ))
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color(white: 0.95))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding()
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        // Lighting
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Lighting")
                                .font(.headline)
                            
                            TextField("e.g., golden hour, soft natural, dramatic", text: Binding(
                                get: { aestheticProfile.lighting ?? "" },
                                set: { aestheticProfile.lighting = $0.isEmpty ? nil : $0 }
                            ))
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color(white: 0.95))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding()
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        // Overall Vibe (Custom Description)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Overall Vibe (Optional)")
                                .font(.headline)
                            
                            Text("Describe the aesthetic in your own words. This will override individual settings.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            TextField("e.g., Warm, dreamy, romantic moments with soft golden lighting...", text: Binding(
                                get: { aestheticProfile.overallVibe ?? "" },
                                set: { aestheticProfile.overallVibe = $0.isEmpty ? nil : $0 }
                            ), axis: .vertical)
                            .textFieldStyle(.plain)
                            .lineLimit(3...6)
                            .padding()
                            .background(Color(white: 0.95))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding()
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        // Preview
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Preview")
                                .font(.headline)
                            
                            Text(aestheticProfile.promptSuffix())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(white: 0.95))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding()
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
                
                // Save button
                VStack {
                    Spacer()
                    
                    Button {
                        saveAesthetic()
                    } label: {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Save Aesthetic")
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
                    .disabled(isSaving)
                }
            }
            .navigationTitle("Aesthetic Settings")
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
    
    private func saveAesthetic() {
        isSaving = true
        
        Task {
            await groupViewModel.updateAestheticProfile(
                groupId: group.id,
                aestheticProfile: aestheticProfile
            )
            isSaving = false
            dismiss()
        }
    }
}

#Preview {
    AestheticSettingsView(
        group: Group(
            id: UUID(),
            name: "Our Dreams",
            inviteCode: "ABC123",
            createdBy: UUID(),
            createdAt: Date(),
            aestheticProfile: nil
        ),
        groupViewModel: GroupViewModel()
    )
}

