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
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    // Deck Selection
                    if !deckService.userDecks.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Add to List")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                            
                            Menu {
                                ForEach(deckService.userDecks) { deck in
                                    Button(action: {
                                        selectedDeckId = deck.id
                                    }) {
                                        HStack {
                                            Text(deck.name)
                                            if selectedDeckId == deck.id {
                                                Spacer()
                                                SwiftUI.Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    if let selectedDeck = deckService.userDecks.first(where: { $0.id == selectedDeckId }) {
                                        Text(selectedDeck.name)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.primary)
                                    } else {
                                        Text("Select a list")
                                            .font(.system(size: 16))
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    SwiftUI.Image(systemName: "chevron.down")
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .padding(12)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.top, 8)
                    }
                    
                    // Search Bar
                    HStack(spacing: 12) {
                        SwiftUI.Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search card by name...", text: $searchText)
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
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding()
                    
                    // Tip View
                    if showTip {
                        HStack(spacing: 12) {
                            SwiftUI.Image(systemName: "hand.tap.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Quick Add")
                                    .font(.system(size: 14, weight: .bold))
                                Text("Double tap to add instantly!")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation {
                                    showTip = false
                                    hasSeenTip = true
                                }
                            }) {
                                SwiftUI.Image(systemName: "xmark")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 12))
                            }
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                    
                    // Results List
                    if isSearching {
                        Spacer()
                        ProgressView()
                        Spacer()
                    } else if searchResults.isEmpty && !searchText.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            SwiftUI.Image(systemName: "magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("No cards found")
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    } else if searchResults.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            SwiftUI.Image(systemName: "text.magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("Search for a card")
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(searchResults) { card in
                                    ManualAddCardRow(
                                        card: card,
                                        isTapped: tappedCardId == card.id,
                                        isAdding: isAddingCard && tappedCardId == card.id
                                    )
                                    .onTapGesture(count: 2) {
                                        // Double tap: Add directly
                                        addCardToDeck(card)
                                    }
                                    .onTapGesture(count: 1) {
                                        // Single tap: Show "tap again" animation
                                        handleSingleTap(card)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
                    }
                }
                
                // Success Toast
                if showSuccessToast {
                    VStack {
                        HStack {
                            SwiftUI.Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("\(addedCardName) added!")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Material.thinMaterial)
                        .cornerRadius(20)
                        .shadow(radius: 4)
                    }
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Add Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Select first deck by default
                if selectedDeckId == nil, let firstDeck = deckService.userDecks.first {
                    selectedDeckId = firstDeck.id
                }
                
                if !hasSeenTip {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            showTip = true
                        }
                    }
                }
            }
        }
    }
    
    private func handleSingleTap(_ card: CardTemplate) {
        if tappedCardId == card.id {
            // Second tap - add to deck
            addCardToDeck(card)
        } else {
            // First tap - show "tap again" state
            withAnimation {
                tappedCardId = card.id
            }
            
            // Reset after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                if tappedCardId == card.id {
                    withAnimation {
                        tappedCardId = nil
                    }
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
            try? await Task.sleep(nanoseconds: 500_000_000) // Debounce
            
            guard !Task.isCancelled else { return }
            
            // Use real search API
            cardService.searchCardTemplates(query: query) { result in
                Task { @MainActor in
                    isSearching = false
                    switch result {
                    case .success(let cards):
                        searchResults = cards
                    case .failure:
                        searchResults = []
                    }
                }
            }
        }
    }
    
    private func addCardToDeck(_ template: CardTemplate) {
        guard let deckId = selectedDeckId else {
            // Show error - no deck selected
            return
        }
        
        guard let userId = authService.currentUserId else {
            // Show error - not authenticated
            return
        }
        
        guard !isAddingCard else { return }
        
        isAddingCard = true
        tappedCardId = template.id
        
        // Call the API to add card template to deck
        deckService.addCardTemplateToDeck(deckId: deckId, templateId: template.id, userId: userId) { result in
            Task { @MainActor in
                isAddingCard = false
                
                switch result {
                case .success:
                    // Show success feedback
                    addedCardName = template.name
                    withAnimation {
                        showSuccessToast = true
                        tappedCardId = nil
                    }
                    
                    // Haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    
                    // Hide toast after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            showSuccessToast = false
                        }
                    }
                    
                case .failure(let error):
                    print("Error adding card: \(error.localizedDescription)")
                    tappedCardId = nil
                }
            }
        }
    }
}

struct ManualAddCardRow: View {
    let card: CardTemplate
    let isTapped: Bool
    let isAdding: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Card Image
            CachedAsyncImage(url: URL(string: card.fullImageUrl ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fit)
                case .failure, .empty:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            SwiftUI.Image(systemName: "photo")
                                .foregroundColor(.secondary)
                        )
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 50, height: 70)
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(card.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                
                if isTapped && !isAdding {
                    Text("Tap again to add")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.blue)
                        .transition(.opacity.combined(with: .scale))
                } else {
                    HStack(spacing: 8) {
                        Text(card.setCode)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Text(card.rarity.displayName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(card.rarity.color)
                    }
                }
            }
            
            Spacer()
            
            // Visual cue for interaction
            if isAdding {
                ProgressView()
                    .scaleEffect(0.8)
            } else if isTapped {
                SwiftUI.Image(systemName: "hand.tap.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                    .padding(8)
                    .background(Color.blue.opacity(0.2))
                    .clipShape(Circle())
                    .transition(.scale)
            } else {
                SwiftUI.Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                    .padding(8)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(12)
        .background(isTapped ? Color.blue.opacity(0.05) : Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(isTapped ? 0.1 : 0.05), radius: isTapped ? 8 : 5, x: 0, y: 2)
        .scaleEffect(isTapped ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isTapped)
        .contentShape(Rectangle())
    }
}