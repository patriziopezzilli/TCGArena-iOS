//
//  SetDetailView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/15/25.
//

import SwiftUI

// MARK: - Set Cards Cache Manager
class SetCardsCache {
    static let shared = SetCardsCache()
    
    private var cache: [Int64: [CardTemplate]] = [:]
    private var cacheTimestamps: [Int64: Date] = [:]
    private let cacheValidityDuration: TimeInterval = 3 * 60 * 60 // 3 hours
    
    private init() {}
    
    func getCards(for setId: Int64) -> [CardTemplate]? {
        guard let cards = cache[setId],
              let timestamp = cacheTimestamps[setId],
              Date().timeIntervalSince(timestamp) < cacheValidityDuration else {
            return nil
        }
        return cards
    }
    
    func setCards(_ cards: [CardTemplate], for setId: Int64) {
        cache[setId] = cards
        cacheTimestamps[setId] = Date()
    }
    
    func clearCache() {
        cache.removeAll()
        cacheTimestamps.removeAll()
    }
}

struct SetDetailView: View {
    let set: TCGSet
    @StateObject private var expansionService = ExpansionService()
    @EnvironmentObject private var marketService: MarketDataService
    @State private var cards: [CardTemplate] = []
    @State private var isLoading = true
    @State private var searchText = ""
    
    private var filteredCards: [CardTemplate] {
        if searchText.isEmpty {
            return cards
        } else {
            return cards.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    private var cardColor: Color {
        let hash = abs(set.setCode.hashValue)
        let hue = Double(hash % 360) / 360.0
        return Color(hue: hue, saturation: 0.6, brightness: 0.8)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Section
                setHeaderSection
                
                // Search Bar
                searchBarView
                
                // Cards Section
                cardsSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color(.systemBackground))
        .task {
            await loadCards()
        }
    }
    
    // MARK: - Header Section
    private var setHeaderSection: some View {
        VStack(spacing: 16) {
            // Set Image - Hide if loading fails
            if let logoUrl = set.logoUrl, let url = URL(string: logoUrl) {
                CachedAsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.blue.opacity(0.2))
                            .frame(height: 180)
                            .overlay(
                                ProgressView()
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    case .failure(_):
                        EmptyView() // Hide image completely if it fails to load
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            
            // Set Info
            VStack(spacing: 8) {
                Text(set.name)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(cardColor)
                        .frame(width: 8, height: 8)
                        
                    Text("\(set.cardCount) Cards")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(cardColor.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(cardColor.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Search Bar
    private var searchBarView: some View {
        VStack(spacing: 0) {
            HStack {
                SwiftUI.Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 16, weight: .medium))
                
                TextField("Search cards by name...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 16, weight: .medium))
                
                if !searchText.isEmpty {
                    Button(action: { 
                        withAnimation(.easeInOut(duration: 0.2)) {
                            searchText = "" 
                        }
                    }) {
                        SwiftUI.Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 16, weight: .medium))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemFill))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(searchText.isEmpty ? Color.clear : Color.blue.opacity(0.5), lineWidth: 1.5)
                    )
            )
        }
    }
    
    // MARK: - Cards Section
    private var cardsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("Cards in this Set")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !searchText.isEmpty {
                    Text("\(filteredCards.count) of \(cards.count)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            if isLoading {
                ProgressView("Loading cards...")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else if filteredCards.isEmpty {
                if searchText.isEmpty {
                    emptyCardsView
                } else {
                    noSearchResultsView
                }
            } else {
                // Cards Grid
                let columns = [
                    GridItem(.adaptive(minimum: 100, maximum: 120), spacing: 12)
                ]
                
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(filteredCards) { card in
                        NavigationLink(destination: CardDetailView(card: Card(from: card), isFromDiscover: true).environmentObject(marketService)) {
                            SetDetailCardView(card: Card(from: card))
                        }
                    }
                }
            }
        }
    }
    
    private var emptyCardsView: some View {
        VStack(spacing: 16) {
            SwiftUI.Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 40, weight: .medium))
                .foregroundColor(.secondary)
            
            Text("No cards available")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private var noSearchResultsView: some View {
        VStack(spacing: 16) {
            SwiftUI.Image(systemName: "magnifyingglass")
                .font(.system(size: 40, weight: .medium))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No cards found")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text("Try a different search term")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Actions
    private func loadCards() async {
        // Check cache first
        if let cachedCards = SetCardsCache.shared.getCards(for: set.id), !cachedCards.isEmpty {
            Swift.print("💾 Using cached cards for set \(set.name): \(cachedCards.count) cards")
            self.cards = cachedCards
            isLoading = false
            return
        }
        
        isLoading = true
        
        Swift.print("🎯 Loading cards for set: \(set.name) (ID: \(set.id), cardCount: \(set.cardCount))")
        
        // Use pre-loaded cards from the set if available
        if let preloadedCards = set.cards, !preloadedCards.isEmpty {
            Swift.print("💾 Using pre-loaded cards: \(preloadedCards.count) cards")
            cards = preloadedCards
            SetCardsCache.shared.setCards(preloadedCards, for: set.id)
        } else {
            // Load all cards from backend with pagination
            await loadAllCardsForSet()
        }
        
        isLoading = false
    }
    
    private func loadAllCardsForSet() async {
        var allCards: [CardTemplate] = []
        var currentPage = 1
        let pageSize = 20  // Riduciamo ulteriormente per testare la paginazione
        
        Swift.print("🔄 Starting to load all cards for set \(set.name) (ID: \(set.id))")
        
        Swift.print("📊 Set should have \(set.cardCount) cards according to metadata")
        Swift.print("🔍 Investigating potential data inconsistency...")
        
        // Check if this is a known issue with this set
        if set.cardCount > 0 && set.cardCount < 10 {
            Swift.print("⚠️ WARNING: Set has very few cards (\(set.cardCount)), this might be correct")
        } else if set.cardCount >= 10 {
            Swift.print("⚠️ WARNING: Set metadata claims \(set.cardCount) cards but we're getting very few from API")
        }
        
        while true {
            let cardsPage = await loadCardsPage(currentPage, limit: pageSize)
            
            Swift.print("📄 Page \(currentPage): loaded \(cardsPage.count) cards")
            
            if cardsPage.isEmpty {
                // No more cards to load
                Swift.print("✅ No more cards to load, stopping at page \(currentPage)")
                break
            }
            
            allCards.append(contentsOf: cardsPage)
            currentPage += 1
            
            // Safety check: prevent infinite loops
            if currentPage > 100 {  // Aumentiamo il limite di sicurezza
                Swift.print("⚠️ Safety limit reached (50 pages), stopping")
                break
            }
        }
        
        Swift.print("📊 Total cards loaded for set \(set.name): \(allCards.count)")
        
        // Analyze the results
        if allCards.count == 0 {
            Swift.print("🚨 CRITICAL: No cards loaded at all!")
        } else if allCards.count < set.cardCount * Int(0.1) {  // Less than 10% of expected cards
            Swift.print("🚨 CRITICAL: Loaded only \(allCards.count) cards out of \(set.cardCount) expected (\(String(format: "%.1f", Double(allCards.count)/Double(set.cardCount)*100))%)")
        } else if allCards.count < set.cardCount {
            Swift.print("⚠️ WARNING: Loaded \(allCards.count) cards out of \(set.cardCount) expected (\(String(format: "%.1f", Double(allCards.count)/Double(set.cardCount)*100))%)")
        } else {
            Swift.print("✅ SUCCESS: Loaded all expected cards (\(allCards.count)/\(set.cardCount))")
        }
        
        if allCards.isEmpty {
            // Fallback: create mock cards if backend fails
            Swift.print("❌ No cards loaded from backend, using mock cards")
            self.cards = self.createMockCards()
        } else {
            self.cards = allCards
            // Cache the loaded cards
            SetCardsCache.shared.setCards(allCards, for: set.id)
        }
    }
    
    private func loadCardsPage(_ page: Int, limit: Int) async -> [CardTemplate] {
        await withCheckedContinuation { continuation in
            Swift.print("🌐 Requesting page \(page) with limit \(limit) for set \(set.id) - expecting up to \(limit) cards")
            expansionService.getCardsForSet(set.id, page: page, limit: limit) { result in
                switch result {
                case .success(let loadedCards):
                    Swift.print("✅ Successfully loaded \(loadedCards.count) cards for page \(page) (requested limit: \(limit))")
                    if loadedCards.count < limit && loadedCards.count > 0 {
                        Swift.print("ℹ️ INFO: Received \(loadedCards.count) cards (less than limit \(limit)) - might be last page")
                    } else if loadedCards.count == 0 {
                        Swift.print("ℹ️ INFO: Received 0 cards - this is the last page")
                    } else if loadedCards.count == limit {
                        Swift.print("ℹ️ INFO: Received exactly \(limit) cards - there might be more pages")
                    }
                    continuation.resume(returning: loadedCards)
                case .failure(let error):
                    Swift.print("❌ Failed to load cards for page \(page): \(error.localizedDescription)")
                    continuation.resume(returning: [])
                }
            }
        }
    }
    
    private func createMockCards() -> [CardTemplate] {
        // Create some mock cards for demonstration
        let mockCards = [
            CardTemplate(
                id: Int64(set.id * 100 + 1),
                name: "Mock Card 1",
                tcgType: .magic,
                setCode: set.setCode,
                expansion: nil,
                rarity: .rare,
                cardNumber: "1/100",
                description: "A mock card for testing",
                imageUrl: nil,
                marketPrice: 5.99,
                manaCost: 3,
                dateCreated: Date()
            ),
            CardTemplate(
                id: Int64(set.id * 100 + 2),
                name: "Mock Card 2",
                tcgType: .magic,
                setCode: set.setCode,
                expansion: nil,
                rarity: .uncommon,
                cardNumber: "2/100",
                description: "Another mock card",
                imageUrl: nil,
                marketPrice: 2.50,
                manaCost: 2,
                dateCreated: Date()
            ),
            CardTemplate(
                id: Int64(set.id * 100 + 3),
                name: "Mock Card 3",
                tcgType: .magic,
                setCode: set.setCode,
                expansion: nil,
                rarity: .common,
                cardNumber: "3/100",
                description: "Third mock card",
                imageUrl: nil,
                marketPrice: 0.50,
                manaCost: 1,
                dateCreated: Date()
            )
        ]
        return mockCards
    }
}

struct SetDetailCardView: View {
    let card: Card
    
    var body: some View {
        VStack(spacing: 0) {
            // Card Image
            CachedAsyncImage(url: URL(string: card.fullImageURL ?? "")) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: 8)
                        .fill((card.tcgType?.themeColor ?? Color.gray).opacity(0.2))
                        .aspectRatio(2.5/3.5, contentMode: .fit)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                case .failure(_):
                    RoundedRectangle(cornerRadius: 8)
                        .fill((card.tcgType?.themeColor ?? Color.gray).opacity(0.2))
                        .aspectRatio(2.5/3.5, contentMode: .fit)
                        .overlay(
                            Group {
                                if let tcgType = card.tcgType {
                                    TCGIconView(tcgType: tcgType, size: 24)
                                } else {
                                    SwiftUI.Image(systemName: "questionmark.circle")
                                        .font(.system(size: 24))
                                        .foregroundColor(.gray)
                                }
                            }
                        )
                @unknown default:
                    RoundedRectangle(cornerRadius: 8)
                        .fill((card.tcgType?.themeColor ?? Color.gray).opacity(0.2))
                        .aspectRatio(2.5/3.5, contentMode: .fit)
                }
            }
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            
            // Minimal Info
            Text(card.cardNumber ?? "")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
    }
}

#Preview {
    let mockSet = TCGSet(
        id: 123,
        name: "Mock Set",
        setCode: "MST",
        imageURL: nil,
        releaseDateString: "2023-01-01T00:00:00Z",
        cardCount: 100,
        description: "A mock set for testing",
        productType: nil,
        parentSetId: nil,
        cards: []
    )
    SetDetailView(set: mockSet)
}
