//
//  CreateDeckView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/30/25.
//

import SwiftUI

struct CreateDeckView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var deckService: DeckService
    
    let userId: Int64
    
    @State private var deckName = ""
    @State private var deckDescription = ""
    @State private var selectedTCGType: TCGType = .pokemon
    @State private var selectedDeckType: DeckType = .lista
    @State private var isCreating = false
    
    // Animation states
    // @State private var animateGradient = false
    
    private var accentColor: Color {
        selectedTCGType.themeColor
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dynamic Background
                backgroundLayer
                
                // Main Content - No ScrollView
                VStack(spacing: 0) {
                    // Header
                    headerSection
                        .padding(.vertical, 20)
                    
                    // Central Form Card
                    VStack(spacing: 24) {
                        inputSection
                        
                        Divider()
                            .background(Color.primary.opacity(0.1))
                        
                        deckTypeSection
                        
                        gameTypeSection
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(.systemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(accentColor.opacity(0.2), lineWidth: 2)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Bottom Button
                    createButton
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        SwiftUI.Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
            }
        }
    }
    
    // MARK: - Background
    private var backgroundLayer: some View {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 4) {
            Text("Nuova collezione")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.primary, .primary.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Text("Create your collection")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Input Section
    private var inputSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Label("NAME", systemImage: "character.cursor.ibeam")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                
                TextField("e.g., Master Collection", text: $deckName)
                    .font(.system(size: 17, weight: .medium))
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Label("DESCRIPTION", systemImage: "text.alignleft")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                
                TextField("Optional description...", text: $deckDescription)
                    .font(.system(size: 16))
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Deck Type Section
    private var deckTypeSection: some View {
        HStack(spacing: 12) {
            DeckTypeOption(
                title: "Collection",
                icon: "list.bullet.rectangle.fill",
                isSelected: selectedDeckType == .lista,
                color: .green
            ) {
                withAnimation { selectedDeckType = .lista }
            }
            
            DeckTypeOption(
                title: "Playable Deck",
                icon: "rectangle.stack.fill",
                isSelected: selectedDeckType == .deck,
                color: .blue
            ) {
                withAnimation { selectedDeckType = .deck }
            }
        }
        .frame(height: 56)
    }
    
    // MARK: - Game Type Section
    private var gameTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("TCG", systemImage: "gamecontroller.fill")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(TCGType.allCases, id: \.self) { tcg in
                        GameTypeOption(
                            tcg: tcg,
                            isSelected: selectedTCGType == tcg
                        ) {
                            withAnimation { selectedTCGType = tcg }
                        }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
            }
        }
    }
    
    // MARK: - Create Button
    private var createButton: some View {
        Button(action: createDeck) {
            HStack {
                if isCreating {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(selectedDeckType == .lista ? "Create Collection" : "Create Deck")
                        .font(.headline)
                    SwiftUI.Image(systemName: "arrow.right")
                        .font(.headline)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: canCreateDeck ? [accentColor, accentColor.opacity(0.8)] : [.gray, .gray.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .shadow(color: canCreateDeck ? accentColor.opacity(0.4) : .clear, radius: 10, x: 0, y: 5)
        }
        .disabled(!canCreateDeck || isCreating)
    }
    
    // MARK: - Logic
    private var canCreateDeck: Bool {
        !deckName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func createDeck() {
        guard canCreateDeck else { return }
        
        isCreating = true
        let trimmedName = deckName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = deckDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        
        deckService.createDeck(
            name: trimmedName,
            description: trimmedDescription.isEmpty ? nil : trimmedDescription,
            tcgType: selectedTCGType,
            deckType: selectedDeckType,
            userId: userId
        ) { result in
            DispatchQueue.main.async {
                isCreating = false
                switch result {
                case .success:
                    // Haptic feedback for successful creation
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    
                    // Show points toast before dismissing
                    ToastManager.shared.showSuccess("🎉 +10 punti!")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        dismiss()
                    }
                case .failure(let error):
                    ToastManager.shared.showError(error.localizedDescription)
                }
            }
        }
    }
}

// MARK: - Subviews
struct DeckTypeOption: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                SwiftUI.Image(systemName: icon)
                    .font(.system(size: 18))
                Text(title)
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : .primary)
            .frame(maxWidth: .infinity)
            .frame(maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? color : Color(.systemBackground).opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 1)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

struct GameTypeOption: View {
    let tcg: TCGType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? tcg.themeColor : Color.gray.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    SwiftUI.Image(systemName: tcg.systemIcon)
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? .white : tcg.themeColor)
                }
                .shadow(color: isSelected ? tcg.themeColor.opacity(0.4) : .clear, radius: 4, y: 2)
                
                Text(tcg.shortName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
            .scaleEffect(isSelected ? 1.1 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Extensions
extension TCGType {
    var shortName: String {
        switch self {
        case .pokemon: return "Pokémon"
        case .magic: return "Magic"
        case .yugioh: return "Yu-Gi-Oh!"
        case .onePiece: return "One Piece"
        case .digimon: return "Digimon"
        case .dragonBall: return "Dragon Ball"
        case .lorcana: return "Lorcana"
        }
    }
}

#Preview {
    CreateDeckView(userId: 1)
        .environmentObject(DeckService())
}
