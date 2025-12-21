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
    
    private var accentColor: Color {
        selectedTCGType.themeColor
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    
                    // MARK: - Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nuova Collezione")
                            .font(.system(size: 34, weight: .heavy))
                            .foregroundColor(.primary)
                        
                        Text("Crea una nuova lista o un mazzo giocabile")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    
                    Divider()
                        .padding(.leading, 24)
                    
                    // MARK: - Input Section
                    VStack(spacing: 24) {
                        // Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("NOME")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                                .tracking(0.5)
                            
                            TextField("e.g. Master Collection", text: $deckName)
                                .font(.system(size: 18, weight: .medium))
                                .padding(16)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                        }
                        
                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("DESCRIZIONE (OPZIONALE)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                                .tracking(0.5)
                            
                            TextField("Breve descrizione...", text: $deckDescription)
                                .font(.system(size: 18, weight: .medium))
                                .padding(16)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // MARK: - Deck Type Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("TIPO DI RACCOLTA")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                            .tracking(0.5)
                            .padding(.horizontal, 24)
                        
                        HStack(spacing: 12) {
                            DeckTypeOption(
                                title: "Collezione",
                                icon: "list.bullet.rectangle.fill",
                                isSelected: selectedDeckType == .lista,
                                color: .green
                            ) {
                                withAnimation { selectedDeckType = .lista }
                            }
                            
                            DeckTypeOption(
                                title: "Mazzo Giocabile",
                                icon: "rectangle.stack.fill",
                                isSelected: selectedDeckType == .deck,
                                color: .blue
                            ) {
                                withAnimation { selectedDeckType = .deck }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    // MARK: - Game Type Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("GIOCO (TCG)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                            .tracking(0.5)
                            .padding(.horizontal, 24)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(TCGType.allCases, id: \.self) { tcg in
                                    GameTypeOption(
                                        tcg: tcg,
                                        isSelected: selectedTCGType == tcg
                                    ) {
                                        withAnimation { selectedTCGType = tcg }
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    
                    Spacer()
                        .frame(height: 40)
                    
                    // MARK: - Create Button
                    Button(action: createDeck) {
                        HStack {
                            if isCreating {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.trailing, 8)
                            }
                            Text(selectedDeckType == .lista ? "Crea Collezione" : "Crea Mazzo")
                                .font(.system(size: 17, weight: .semibold))
                            
                            if !isCreating {
                                SwiftUI.Image(systemName: "arrow.right")
                                    .font(.system(size: 16, weight: .bold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(canCreateDeck ? accentColor : Color(.systemGray4))
                        .cornerRadius(28)
                        .shadow(color: canCreateDeck ? accentColor.opacity(0.3) : .clear, radius: 10, y: 5)
                    }
                    .disabled(!canCreateDeck || isCreating)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        SwiftUI.Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(8)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(Circle())
                    }
                }
            }
        }
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
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? color : Color(.secondarySystemBackground))
            )
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
                        .fill(isSelected ? tcg.themeColor : Color(.secondarySystemBackground))
                        .frame(width: 50, height: 50)
                    
                    TCGIconView(tcgType: tcg, size: 24, color: isSelected ? .white : tcg.themeColor)
                }
                
                Text(tcg.shortName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
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
        case .lorcana: return "Lorcana"
        case .riftbound: return "Riftbound"
        }
    }
}

#Preview {
    CreateDeckView(userId: 1)
        .environmentObject(DeckService())
}
