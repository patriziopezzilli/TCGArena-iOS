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
    
    private var selectedDeck: Deck? {
        deckService.userDecks.first(where: { $0.id == selectedDeckId })
    }
    
    private var accentColor: Color {
        selectedDeck?.tcgType.themeColor ?? .blue
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Section
            VStack(spacing: 20) {
                // Title
                VStack(spacing: 4) {
                    Text("Aggiungi Carta")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("Cerca e aggiungi alla tua collezione")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 20)
                
                // Deck Selector
                if !deckService.userDecks.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(deckService.userDecks) { deck in
                                DeckSelectionPill(
                                    deck: deck,
                                    isSelected: selectedDeckId == deck.id,
                                    accentColor: deck.tcgType.themeColor
                                ) {
                                    withAnimation { selectedDeckId = deck.id }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 4)
                    }
                    .frame(height: 50)
                }
                
                // Search Bar
                HStack(spacing: 12) {
                    SwiftUI.Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(accentColor)
                    
                    TextField("Cerca carta...", text: $searchText)
                        .font(.system(size: 16))
                        .onChange(of: searchText) { newValue in
                            performSearch(query: newValue)
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            SwiftUI.Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(accentColor.opacity(0.3), lineWidth: 1.5)
                )
                .padding(.horizontal, 20)
            }
            .padding(.top, 10)
            .padding(.bottom, 20)
            
            // Results Area
            ZStack {
                if isSearching {
                    ProgressView()
                        .tint(accentColor)
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    ManualAddEmptyStateView(
                        icon: "magnifyingglass",
                        title: "Nessun risultato",
                        message: "Prova a cercare con un nome diverso",
                        color: .orange
                    )
                } else if searchResults.isEmpty {
                    ManualAddEmptyStateView(
                        icon: "sparkles",
                        title: "Inizia la ricerca",
                        message: "Digita il nome della carta che vuoi aggiungere",
                        color: accentColor
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(searchResults) { card in
                                CardResultRow(
                                    card: card,
                                    isTapped: tappedCardId == card.id,
                                    isAdding: isAddingCard && tappedCardId == card.id,
                                    accentColor: accentColor
                                )
                                .onTapGesture(count: 2) {
                                    addCardToDeck(card)
                                }
                                .onTapGesture(count: 1) {
                                    handleSingleTap(card)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        .padding(.bottom, 20)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(.systemBackground))
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
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
                .padding(.bottom, 40)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .overlay(alignment: .bottom) {
            // Tip Overlay
            if showTip {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Doppio tocco veloce!")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Tocca due volte una carta per aggiungerla subito")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Button(action: {
                        withAnimation {
                            showTip = false
                            hasSeenTip = true
                        }
                    }) {
                        SwiftUI.Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(accentColor)
                        .shadow(radius: 10)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            if selectedDeckId == nil, let firstDeck = deckService.userDecks.first {
                selectedDeckId = firstDeck.id
            }
            
            if !hasSeenTip {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation { showTip = true }
                }
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
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    
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

// MARK: - Subviews
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
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? accentColor.opacity(0.15) : Color(.secondarySystemBackground))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? accentColor : Color.clear, lineWidth: 1.5)
            )
            .foregroundColor(isSelected ? accentColor : .secondary)
        }
        .buttonStyle(.plain)
    }
}

struct CardResultRow: View {
    let card: CardTemplate
    let isTapped: Bool
    let isAdding: Bool
    let accentColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Image
            CachedAsyncImage(url: URL(string: card.fullImageUrl ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fit)
                case .failure, .empty:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.1))
                        .overlay(SwiftUI.Image(systemName: "photo").foregroundColor(.secondary))
                @unknown default: EmptyView()
                }
            }
            .frame(width: 48, height: 66)
            .cornerRadius(6)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(card.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if isTapped && !isAdding {
                    Text("Tocca ancora per aggiungere")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(accentColor)
                        .transition(.opacity)
                } else {
                    HStack(spacing: 6) {
                        Text(card.setCode)
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(4)
                        
                        Text(card.rarity.displayName)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Action Icon
            ZStack {
                if isAdding {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Circle()
                        .fill(isTapped ? accentColor : Color(.secondarySystemBackground))
                        .frame(width: 32, height: 32)
                    
                    SwiftUI.Image(systemName: isTapped ? "plus" : "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(isTapped ? .white : .secondary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: isTapped ? accentColor.opacity(0.2) : Color.black.opacity(0.05), radius: isTapped ? 12 : 5, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isTapped ? accentColor : Color.clear, lineWidth: 1.5)
        )
        .scaleEffect(isTapped ? 1.02 : 1.0)
    }
}

struct ManualAddEmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                SwiftUI.Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            Spacer()
            Spacer()
        }
    }
}
