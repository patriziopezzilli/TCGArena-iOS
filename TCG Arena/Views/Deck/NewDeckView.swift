//
//  NewDeckView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/10/25.
//

import SwiftUI

struct NewDeckView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var deckService: DeckService
    @EnvironmentObject var authService: AuthService
    
    @State private var deckName = ""
    @State private var selectedTCG: TCGType = .pokemon
    @State private var deckDescription = ""
    @State private var isPublic = false
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var isSaving = false
    @State private var showSuccess = false
    
    private let predefinedTags = ["Competitive", "Casual", "Budget", "Meta", "Fun", "Experimental", "Tournament", "Beginner"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [selectedTCG.themeColor, selectedTCG.themeColor.opacity(0.7)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 70, height: 70)
                            
                            SwiftUI.Image(systemName: "square.stack.3d.up.fill")
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 4) {
                            Text("Create New Deck")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("Build your perfect deck")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 16)
                    
                    // Basic Information
                    VStack(spacing: 16) {
                        SectionHeaderView(title: "Basic Information", subtitle: "Name and game details")
                        
                        VStack(spacing: 14) {
                            // Deck Name
                            ModernTextField(
                                title: "Deck Name",
                                text: $deckName,
                                icon: "textformat"
                            )
                            
                            // TCG Type Selector
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Game Type")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                    ForEach(TCGType.allCases, id: \.self) { tcgType in
                                        Button(action: {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                selectedTCG = tcgType
                                            }
                                        }) {
                                            HStack(spacing: 10) {
                                                SwiftUI.Image(systemName: tcgType.systemIcon)
                                                    .font(.system(size: 16, weight: .medium))
                                                    .foregroundColor(selectedTCG == tcgType ? .white : tcgType.themeColor)
                                                
                                                Text(tcgType.displayName)
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundColor(selectedTCG == tcgType ? .white : .primary)
                                                    .multilineTextAlignment(.leading)
                                                
                                                Spacer()
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 14)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(selectedTCG == tcgType ? tcgType.themeColor : Color(.systemGray6))
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(selectedTCG == tcgType ? tcgType.themeColor : Color.clear, lineWidth: 2)
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Description & Settings
                    VStack(spacing: 16) {
                        SectionHeaderView(title: "Description & Settings", subtitle: "Optional details")
                        
                        VStack(spacing: 14) {
                            // Description
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description (Optional)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                ZStack(alignment: .topLeading) {
                                    if deckDescription.isEmpty {
                                        Text("Describe your deck strategy, playstyle, or key cards...")
                                            .foregroundColor(.secondary)
                                            .padding(.top, 12)
                                            .padding(.leading, 16)
                                            .font(.system(size: 15))
                                    }
                                    
                                    TextEditor(text: $deckDescription)
                                        .frame(minHeight: 80)
                                        .padding(12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color(.systemGray6))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color(.systemGray4), lineWidth: 1)
                                        )
                                }
                            }
                            
                            // Public Toggle
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Visibility")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Toggle(isOn: $isPublic) {
                                    HStack(spacing: 12) {
                                        SwiftUI.Image(systemName: isPublic ? "globe" : "lock")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(isPublic ? selectedTCG.themeColor : .secondary)
                                            .frame(width: 20)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(isPublic ? "Public Deck" : "Private Deck")
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundColor(.primary)
                                            
                                            Text(isPublic ? "Visible to community" : "Only you can see this deck")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                    }
                                }
                                .toggleStyle(SwitchToggleStyle(tint: selectedTCG.themeColor))
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                )
                            }
                            
                            // Tags Section
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Tags (Optional)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                // Selected Tags
                                if !tags.isEmpty {
                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                                        ForEach(tags, id: \.self) { tag in
                                            HStack(spacing: 6) {
                                                Text(tag)
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundColor(.white)
                                                
                                                Button(action: { removeTag(tag) }) {
                                                    SwiftUI.Image(systemName: "xmark")
                                                        .font(.system(size: 10, weight: .bold))
                                                        .foregroundColor(.white)
                                                }
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(
                                                Capsule()
                                                    .fill(selectedTCG.themeColor)
                                            )
                                        }
                                    }
                                }
                                
                                // Predefined Tags
                                Text("Quick Tags:")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .padding(.top, 8)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 6) {
                                    ForEach(predefinedTags.filter { !tags.contains($0) }, id: \.self) { tag in
                                        Button(action: { addTag(tag) }) {
                                            Text(tag)
                                                .font(.system(size: 11, weight: .medium))
                                                .foregroundColor(selectedTCG.themeColor)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(
                                                    Capsule()
                                                        .stroke(selectedTCG.themeColor.opacity(0.5), lineWidth: 1)
                                                )
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Create Button
                    LoadingButton(
                        title: "Create Deck",
                        loadingTitle: "Creating Deck...",
                        isLoading: isSaving,
                        isDisabled: deckName.isEmpty,
                        color: selectedTCG.themeColor,
                        action: createDeck
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("New Deck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if isSaving {
                    LoadingOverlay(message: "Creating your deck...")
                }
            }
            .overlay {
                if showSuccess {
                    SuccessAnimation()
                }
            }
        }
    }
    
    // MARK: - Actions
    private func addTag(_ tag: String) {
        if !tags.contains(tag) && tags.count < 5 {
            withAnimation(.easeInOut(duration: 0.2)) {
                tags.append(tag)
            }
        }
    }
    
    private func removeTag(_ tag: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            tags.removeAll { $0 == tag }
        }
    }
    
    private func createDeck() {
        guard !deckName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isSaving = true
        
        let userId = authService.currentUserId ?? 1 // Use real user ID from auth service
        
        deckService.createDeck(
            name: deckName.trimmingCharacters(in: .whitespacesAndNewlines),
            description: deckDescription.isEmpty ? nil : deckDescription,
            tcgType: selectedTCG,
            deckType: .deck, // Default deck type
            userId: userId
        ) { result in
            DispatchQueue.main.async {
                isSaving = false
                switch result {
                case .success(let createdDeck):
                    print("✅ NewDeckView: Deck created successfully: \(createdDeck.name)")
                    showSuccess = true
                    
                    // Auto dismiss after success
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                case .failure(let error):
                    print("🔴 NewDeckView: Failed to create deck: \(error.localizedDescription)")
                    // TODO: Show error alert
                }
            }
        }
    }
}

#Preview {
    NewDeckView()
        .environmentObject(DeckService())
        .environmentObject(AuthService())
}