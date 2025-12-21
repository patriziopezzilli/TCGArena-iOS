//
//  ManualAddCardView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/10/25.
//

import SwiftUI

struct ManualAddCardView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var cardService: CardService
    @EnvironmentObject var deckService: DeckService
    @EnvironmentObject var authService: AuthService
    
    @State private var searchText = ""
    @State private var searchResults: [CardTemplate] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?
    @State private var selectedDeckId: Int64?
    @State private var tappedCardId: Int64?
    @State private var showSuccessToast = false
    @State private var addedCardName = ""
    @State private var isAddingCard = false
    
    @AppStorage("hasSeenManualAddTip") private var hasSeenTip = false
    @State private var showTip = false
    
    // Derived properties
    private var selectedDeck: Deck? {
        deckService.userDecks.first(where: { $0.id == selectedDeckId })
    }
    
    private var accentColor: Color {
        selectedDeck?.tcgType.themeColor ?? .blue
    }
    
    // Keep original order but filter for compatibility check
    // We don't dynamically reorder to avoid resetting tapped state
    private var sortedDecks: [Deck] {
        // Just return all decks in their original order
        // Compatibility is shown visually via opacity
        return deckService.userDecks
    }
    
    // Filter decks by the current card's TCG type when a card is selected
    private var filteredDecks: [Deck] {
        guard let tappedId = tappedCardId,
              let card = searchResults.first(where: { $0.id == tappedId }),
              let cardTCG = card.tcgType else {
            // No card selected or card has no TCG type - show all decks
            return deckService.userDecks
        }
        // Filter decks by the card's TCG type
        return deckService.userDecks.filter { $0.tcgType == cardTCG }
    }
    
    // Check if selected deck is compatible with the currently tapped card
    private var isDeckCompatible: Bool {
        guard let tappedId = tappedCardId,
              let card = searchResults.first(where: { $0.id == tappedId }),
              let cardTCG = card.tcgType,
              let deck = selectedDeck else {
            return true // No card selected or no deck - assume compatible
        }
        return deck.tcgType == cardTCG
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header Section
            VStack(alignment: .leading, spacing: 24) {
                // Title
                Text("Cerca Carta")
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 24)
                
                // Deck Selector (Minimal)
                if !deckService.userDecks.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        // Show TCG filter warning if a card is selected
                        if tappedCardId != nil, filteredDecks.count < deckService.userDecks.count {
                            if let card = searchResults.first(where: { $0.id == tappedCardId }),
                               let cardTCG = card.tcgType {
                                HStack(spacing: 6) {
                                    SwiftUI.Image(systemName: "info.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(cardTCG.themeColor)
                                    Text("Solo deck \(cardTCG.displayName)")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(sortedDecks) { deck in
                                    let isCompatible = tappedCardId == nil || {
                                        guard let card = searchResults.first(where: { $0.id == tappedCardId }),
                                              let cardTCG = card.tcgType else { return true }
                                        return deck.tcgType == cardTCG
                                    }()
                                    
                                    DeckSelectionPill(
                                        deck: deck,
                                        isSelected: selectedDeckId == deck.id,
                                        accentColor: deck.tcgType.themeColor,
                                        action: { withAnimation { selectedDeckId = deck.id } }
                                    )
                                    .opacity(isCompatible ? 1.0 : 0.3)
                                    .disabled(!isCompatible)
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                }
                
                // Search Bar (Minimal)
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        SwiftUI.Image(systemName: "magnifyingglass")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        TextField("Cerca per nome, set...", text: $searchText)
                            .font(.system(size: 18, weight: .medium))
                            .onChange(of: searchText) { newValue in
                                performSearch(query: newValue)
                            }
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                SwiftUI.Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color(.tertiaryLabel))
                            }
                        }
                    }
                    
                    if !searchText.isEmpty {
                        Text("💡 Doppio tap per aggiungere veloce")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
                
                Divider()
                    .padding(.leading, 24)
            }
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            // MARK: - Results Area
            ZStack {
                if isSearching {
                    ProgressView()
                        .scaleEffect(1.2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        SwiftUI.Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(Color(.tertiaryLabel))
                        Text("Nessuna carta trovata")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else if searchResults.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        SwiftUI.Image(systemName: "keyboard")
                            .font(.system(size: 48))
                            .foregroundColor(Color(.tertiaryLabel))
                        Text("Inizia a digitare per cercare")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(searchResults) { card in
                                CardResultRow(
                                    card: card,
                                    isTapped: tappedCardId == card.id,
                                    isAdding: isAddingCard && tappedCardId == card.id,
                                    accentColor: accentColor,
                                    onAdd: { addCardToDeck(card) }
                                )
                                .onTapGesture(count: 2) {
                                    HapticManager.shared.mediumImpact()
                                    addCardToDeck(card)
                                }
                                .onTapGesture(count: 1) {
                                    handleSingleTap(card)
                                }
                                
                                Divider()
                                    .padding(.leading, 84) // Align with text
                            }
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .background(Color(.systemBackground))
        .navigationBarHidden(true)
        .overlay(alignment: .topTrailing) {
            Button(action: { dismiss() }) {
                ZStack {
                    Circle()
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: 36, height: 36)
                        
                    SwiftUI.Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.secondary)
                }
            }
            .padding(24)
        }
        .overlay(alignment: .bottom) {
             // Success Toast
             if showSuccessToast {
                 HStack(spacing: 12) {
                     SwiftUI.Image(systemName: "checkmark.circle.fill")
                         .font(.title3)
                         .foregroundColor(.green)
                     
                     Text("\(addedCardName) aggiunta!")
                         .font(.system(size: 15, weight: .semibold))
                         .foregroundColor(.primary)
                 }
                 .padding(.horizontal, 24)
                 .padding(.vertical, 14)
                 .background(
                     Capsule()
                         .fill(.ultraThinMaterial)
                         .shadow(color: Color.black.opacity(0.1), radius: 10, y: 5)
                 )
                 .padding(.bottom, 40)
                 .transition(.move(edge: .bottom).combined(with: .opacity))
             }
        }
        .onAppear {
            if selectedDeckId == nil, let firstDeck = deckService.userDecks.first {
                selectedDeckId = firstDeck.id
            }
        }
    }
    
    // MARK: - Logic
    
    private func handleSingleTap(_ card: CardTemplate) {
        if tappedCardId == card.id {
            addCardToDeck(card)
        } else {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                tappedCardId = card.id
                
                // Auto-select first compatible deck if current deck is incompatible
                if let cardTCG = card.tcgType {
                    let currentDeckCompatible = selectedDeck?.tcgType == cardTCG
                    if !currentDeckCompatible {
                        // Find first compatible deck and select it
                        if let compatibleDeck = deckService.userDecks.first(where: { $0.tcgType == cardTCG }) {
                            selectedDeckId = compatibleDeck.id
                        }
                    }
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                if tappedCardId == card.id {
                    withAnimation { tappedCardId = nil }
                }
            }
        }
    }
    
    private func performSearch(query: String) {
        searchTask?.cancel()
        guard query.count >= 2 else {
            searchResults = []
            isSearching = false
            return
        }
        isSearching = true
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            cardService.searchCardTemplates(query: query) { result in
                Task { @MainActor in
                    isSearching = false
                    switch result {
                    case .success(let cards): searchResults = cards
                    case .failure: searchResults = []
                    }
                }
            }
        }
    }
    
    private func addCardToDeck(_ template: CardTemplate) {
        guard let deckId = selectedDeckId, let userId = authService.currentUserId, !isAddingCard else { return }
        
        // Check TCG compatibility
        if let cardTCG = template.tcgType,
           let deck = selectedDeck,
           deck.tcgType != cardTCG {
            // Dismiss keyboard first so toast is visible
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            // Show error - incompatible TCG
            ToastManager.shared.showError("TCG incompatibile: non puoi aggiungere carte \(cardTCG.displayName) a un deck \(deck.tcgType.displayName)")
            return
        }
        
        isAddingCard = true
        tappedCardId = template.id
        deckService.addCardTemplateToDeck(deckId: deckId, templateId: template.id, userId: userId) { result in
            Task { @MainActor in
                isAddingCard = false
                switch result {
                case .success:
                    addedCardName = template.name
                    withAnimation {
                        showSuccessToast = true
                        tappedCardId = nil
                    }
                    HapticManager.shared.success()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { showSuccessToast = false }
                    }
                case .failure(let error):
                    print("Error: \(error.localizedDescription)")
                    tappedCardId = nil
                }
            }
        }
    }
}

// MARK: - Components

struct DeckSelectionPill: View {
    let deck: Deck
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Circle()
                    .fill(deck.tcgType.themeColor)
                    .frame(width: 8, height: 8)
                
                Text(deck.name)
                    .font(.system(size: 14, weight: isSelected ? .bold : .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? accentColor.opacity(0.1) : Color(.secondarySystemBackground))
            )
            .foregroundColor(isSelected ? accentColor : .secondary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CardResultRow: View {
    let card: CardTemplate
    let isTapped: Bool
    let isAdding: Bool
    let accentColor: Color
    let onAdd: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Image
            CachedAsyncImage(url: URL(string: card.fullImageUrl ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fit)
                default:
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.secondarySystemBackground))
                        .overlay(SwiftUI.Image(systemName: "photo").foregroundColor(.secondary))
                }
            }
            .frame(width: 44, height: 60)
            .cornerRadius(6)
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(card.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(card.setCode)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(4)
                    
                    Text(card.rarity.displayName)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Add Action
                if isAdding {
                Text("Aggiungo...")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(accentColor)
            } else if isTapped {
                Button(action: onAdd) {
                    HStack(spacing: 6) {
                        SwiftUI.Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                        Text("Aggiungi")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(accentColor)
                            .shadow(color: accentColor.opacity(0.4), radius: 6, x: 0, y: 3)
                    )
                }
            } else {
                Button(action: {}) {
                    SwiftUI.Image(systemName: "plus.circle")
                        .font(.system(size: 24))
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .background(isTapped ? accentColor.opacity(0.05) : Color.clear)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isTapped)
    }
}
