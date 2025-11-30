//
//  CollectionView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/5/25.
//

import SwiftUI
import Foundation

struct CollectionView: View {
    @EnvironmentObject var cardService: CardService
    @EnvironmentObject var deckService: DeckService
    @EnvironmentObject var authService: AuthService
    @StateObject private var expansionService = ExpansionService()
    @StateObject private var marketService = MarketDataService()
    @AppStorage("showMarketValues") private var showMarketValues: Bool = true
    @State private var showingAddCard = false
    @State private var selectedTCGType: TCGType? = nil
    @State private var searchText = ""
    @State private var isInitialLoading = true
    @State private var viewMode: ViewMode = .lists
    @State private var selectedCard: Card? = nil
    @State private var isCardActive = false
    
    enum ViewMode {
        case lists, allCards
    }
    
    var filteredCards: [Card] {
        // If userCards is empty, try to populate from decks
        var cards = cardService.userCards
        
        if cards.isEmpty {
            cards = getAllCardsFromDecks()
        }
        
        // Filter by TCG type
        if let tcgType = selectedTCGType {
            cards = cards.filter { $0.tcgType == tcgType }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            cards = cards.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        return cards
    }
    
    var filteredDecks: [Deck] {
        var decks = deckService.userDecks
        
        // Filter by TCG type
        if let tcgType = selectedTCGType {
            decks = decks.filter { $0.tcgType == tcgType }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            decks = decks.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        return decks
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                headerView
                searchBarView
                portfolioCardView
                tcgFilterView
                separatorView
                discoverSectionView
                contentView
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .background(cardNavigationLink)
            .navigationBarItems(trailing: addCardButton)
            .sheet(isPresented: $showingAddCard) {
                NewAddCardView()
                    .environmentObject(cardService)
                    .environmentObject(deckService)
            }
            .onAppear(perform: onAppearAction)
            .task(taskAction)
            .onChange(of: showMarketValues, perform: onChangeAction)
        }
        .background(Color(.systemBackground))
    }
    
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("My Lists")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Button(action: { showingAddCard = true }) {
                    ZStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 32, height: 32)
                        
                        SwiftUI.Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 12)            // View Mode Selector
            Picker("View Mode", selection: $viewMode) {
                Text("Lists (\(deckService.userDecks.count))").tag(ViewMode.lists)
                Text("All Cards (\(filteredCards.count))").tag(ViewMode.allCards)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
    }
    
    private var searchBarView: some View {
        VStack(spacing: 0) {
            HStack {
                SwiftUI.Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 16, weight: .medium))
                
                TextField(viewMode == .lists ? "Search your lists..." : "Search your collection...", text: $searchText)
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
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
    
    private var portfolioCardView: some View {
        Group {
            if showMarketValues, let portfolio = marketService.portfolioSummary {
                PortfolioCard(portfolio: portfolio)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
            }
        }
    }
    
    private var tcgFilterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach([nil] + TCGType.allCases, id: \.self) { tcgType in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTCGType = tcgType
                        }
                    }) {
                        HStack(spacing: 8) {
                            if let type = tcgType {
                                SwiftUI.Image(systemName: type.systemIcon)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(iconColorFor(tcgType, type: type))
                            }
                            
                            Text(tcgType?.displayName ?? "All Games")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(textColorFor(tcgType))
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(backgroundColorFor(tcgType))
                                .shadow(color: selectedTCGType == tcgType ? Color.black.opacity(0.1) : Color.clear, radius: 4, x: 0, y: 2)
                        )
                        .scaleEffect(selectedTCGType == tcgType ? 1.05 : 1.0)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 20)
    }
    
    private var separatorView: some View {
        Rectangle()
            .fill(Color(.separator).opacity(0.5))
            .frame(height: 2)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
    }
    
    private var discoverSectionView: some View {
        DiscoverInfoBox()
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
    }
    
    private var contentView: some View {
        Group {
            if viewMode == .lists {
                if filteredDecks.isEmpty {
                    emptyDecksView
                } else {
                    decksListView
                }
            } else {
                if filteredCards.isEmpty {
                    emptyCardsView
                } else {
                    cardsListView
                }
            }
        }
    }
    
    private var emptyDecksView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 120, height: 120)
                
                    SwiftUI.Image(systemName: "rectangle.stack")
                        .font(.system(size: 50, weight: .medium))
                        .foregroundColor(.blue)
                }
            
                VStack(spacing: 12) {
                    Text("No Lists Yet")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                
                    Text("Create your first list to start collecting cards!")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
            }
        
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 60)
    }
    
    private var decksListView: some View {
        List(filteredDecks) { deck in
            ZStack {
                NavigationLink(destination: DeckDetailView(deck: deck)) {
                    EmptyView()
                }
                .opacity(0)
                
                DeckRowView(deck: deck)
            }
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
        }
        .listStyle(PlainListStyle())
        .background(Color(.systemBackground))
    }
    
    private var emptyCardsView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.0, green: 0.7, blue: 1.0).opacity(0.1))
                        .frame(width: 120, height: 120)
                
                    SwiftUI.Image(systemName: "rectangle.stack")
                        .font(.system(size: 50, weight: .medium))
                        .foregroundColor(Color(red: 0.0, green: 0.7, blue: 1.0))
                }
            
                VStack(spacing: 12) {
                    Text("No Cards Yet")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                
                    Text("Start building your collection!\nScan or add your first cards.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
            }
        
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 60)
    }
    

    
    private var cardsListView: some View {
        List(filteredCards) { card in
            ZStack {
                NavigationLink(destination: CardDetailView(card: card, isFromDiscover: false)) {
                    EmptyView()
                }
                .opacity(0)
                
                CardRowView(card: card, deckService: deckService)
            }
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
        }
        .listStyle(PlainListStyle())
        .background(Color(.systemGroupedBackground))
    }
    
    private var cardNavigationLink: some View {
        Group {
            if selectedCard != nil {
                NavigationLink("", destination: CardDetailView(card: selectedCard!, isFromDiscover: false), isActive: Binding(get: { isCardActive }, set: { isCardActive = $0; if !$0 { selectedCard = nil } }))
            }
        }
    }
    
    private var addCardButton: some View {
        Button(action: { showingAddCard = true }) {
            SwiftUI.Image(systemName: "plus.circle.fill")
                .font(.title2)
                .foregroundColor(TCGTheme.Colors.accent)
        }
    }
    
    private func onAppearAction() {
        if showMarketValues {
            marketService.loadMarketData()
        }
        
        // Load user decks if authenticated - force refresh when returning from navigation
        if let userId = authService.currentUserId {
            deckService.refreshUserDecks(userId: userId) { result in
                switch result {
                case .success(let decks):
                    // Handle success silently
                    break
                case .failure(let error):
                    // Handle error silently
                    break
                }
            }
        }
    }
    
    private func taskAction() async {
        // Se currentUserId è nil, prova a ricaricarlo dal backend
        if authService.currentUserId == nil {
            await authService.reloadUserDataIfNeeded()
            
            // Dopo il reload, se ora abbiamo currentUserId, carica i deck
            if let userId = authService.currentUserId {
                deckService.loadUserDecksIfNeeded(userId: userId) { result in
                    switch result {
                    case .success(let decks):
                        // Handle success silently
                        break
                    case .failure(let error):
                        // Handle error silently
                        break
                    }
                }
            }
        }
    }
    
    private func onChangeAction(_ enabled: Bool) {
        if enabled {
            marketService.loadMarketData()
        }
    }
    
    private func deleteCard(at offsets: IndexSet) {
        cardService.userCards.remove(atOffsets: offsets)
    }
    
    // MARK: - Helper Functions
    private func backgroundColorFor(_ tcgType: TCGType?) -> Color {
        if selectedTCGType == tcgType {
            if let type = tcgType {
                return type.themeColor.opacity(0.9)
            } else {
                return Color.blue.opacity(0.9)
            }
                } else {
            return Color(.secondarySystemFill)
        }
    }
    
    private func iconColorFor(_ tcgType: TCGType?, type: TCGType) -> Color {
        return selectedTCGType == tcgType ? .white : type.themeColor.opacity(0.7)
    }
    
    private func textColorFor(_ tcgType: TCGType?) -> Color {
        return selectedTCGType == tcgType ? .white : .primary.opacity(0.7)
    }
    

    
    private func getAllCardsFromDecks() -> [Card] {
        var cardMap: [Int64: Card] = [:]
        
        for deck in deckService.userDecks {
            for deckCard in deck.cards {
                let cardId = deckCard.cardId
                
                // Fix image URL if needed
                var imageUrl = deckCard.cardImageUrl
                if let url = imageUrl, !url.contains("/high.webp") {
                    imageUrl = "\(url)/high.webp"
                }
                
                if let existingCard = cardMap[cardId] {
                    // Update quantity and deck names
                    var deckNames = existingCard.deckNames ?? []
                    if !deckNames.contains(deck.name) {
                        deckNames.append(deck.name)
                    }
                    
                    let updatedCard = Card(
                        id: existingCard.id,
                        templateId: existingCard.templateId,
                        name: existingCard.name,
                        rarity: existingCard.rarity,
                        condition: existingCard.condition,
                        imageURL: existingCard.imageURL,
                        isFoil: existingCard.isFoil,
                        quantity: existingCard.quantity + deckCard.quantity,
                        ownerId: existingCard.ownerId,
                        createdAt: existingCard.createdAt,
                        updatedAt: existingCard.updatedAt,
                        tcgType: existingCard.tcgType,
                        set: existingCard.set,
                        cardNumber: existingCard.cardNumber,
                        expansion: existingCard.expansion,
                        marketPrice: existingCard.marketPrice,
                        description: existingCard.description
                    )
                    // Manually set deckNames since it's not in init
                    var finalCard = updatedCard
                    finalCard.deckNames = deckNames
                    cardMap[cardId] = finalCard
                } else {
                    // Create new card from deck card
                    let newCard = Card(
                        id: cardId, // Use templateId as ID for uniqueness in list
                        templateId: cardId,
                        name: deckCard.cardName,
                        rarity: .common, // Default
                        condition: .nearMint, // Default
                        imageURL: imageUrl,
                        isFoil: false,
                        quantity: deckCard.quantity,
                        ownerId: deck.ownerId,
                        createdAt: deck.dateCreated,
                        updatedAt: deck.dateModified,
                        tcgType: deck.tcgType,
                        set: nil,
                        cardNumber: nil,
                        expansion: nil,
                        marketPrice: nil,
                        description: nil
                    )
                    // Manually set deckNames
                    var finalCard = newCard
                    finalCard.deckNames = [deck.name]
                    cardMap[cardId] = finalCard
                }
            }
        }
        
        return Array(cardMap.values).sorted { $0.name < $1.name }
    }
}

struct HorizontalCardRowView: View {
    let card: Card
    
    var body: some View {
        HStack(spacing: 16) {
            // Card Image
            if let imageURL = card.fullImageURL, let url = URL(string: imageURL) {
                CachedAsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: 8)
                            .fill((card.tcgType?.themeColor ?? Color.gray).opacity(0.2))
                            .frame(width: 60, height: 84)
                            .overlay(
                                ProgressView()
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 84)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    case .failure(_):
                        RoundedRectangle(cornerRadius: 8)
                            .fill((card.tcgType?.themeColor ?? Color.gray).opacity(0.2))
                            .frame(width: 60, height: 84)
                            .overlay(
                                SwiftUI.Image(systemName: card.tcgType?.systemIcon ?? "questionmark.circle")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(card.tcgType?.themeColor ?? Color.gray)
                            )
                    @unknown default:
                        RoundedRectangle(cornerRadius: 8)
                            .fill((card.tcgType?.themeColor ?? Color.gray).opacity(0.2))
                            .frame(width: 60, height: 84)
                    }
                }
            } else {
                // Placeholder when no image URL
                RoundedRectangle(cornerRadius: 8)
                    .fill((card.tcgType?.themeColor ?? Color.gray).opacity(0.2))
                    .frame(width: 60, height: 84)
                    .overlay(
                        SwiftUI.Image(systemName: card.tcgType?.systemIcon ?? "questionmark.circle")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(card.tcgType?.themeColor ?? Color.gray)
                    )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                // Card Name and Set
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Text(card.set ?? "")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        if let expansion = card.expansion {
                            Button(action: {
                                // Handle expansion tap - we'll add this later
                            }) {
                                ExpansionBadge(expansion: expansion) {
                                    // Handle expansion tap
                                }
                            }
                        }
                    }
                }
                
                // Rarity and Condition
                HStack(spacing: 12) {
                    // Rarity
                    HStack(spacing: 4) {
                        ForEach(0..<rarityStars(card.rarity), id: \.self) { _ in
                            SwiftUI.Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(rarityColor(card.rarity))
                        }
                    }
                    
                    // Condition
                    Text(card.condition.rawValue)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(conditionColor(card.condition))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(conditionColor(card.condition).opacity(0.1))
                        )
                }
                
                // Deck Reference
                if let deckNames = card.deckNames, !deckNames.isEmpty {
                    HStack(spacing: 4) {
                        SwiftUI.Image(systemName: "rectangle.stack")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        
                        Text("Found in: \(deckNames.joined(separator: ", "))")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            // Price and TCG Badge
            VStack(alignment: .trailing, spacing: 8) {
                if let price = card.marketPrice {
                    Text("€\(String(format: "%.2f", price))")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                SwiftUI.Image(systemName: card.tcgType.map { tcgIcon($0) } ?? "questionmark.circle")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(card.tcgType?.themeColor ?? Color.gray)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill((card.tcgType?.themeColor ?? Color.gray).opacity(0.1))
                    )
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Discover Info Box
struct DiscoverInfoBox: View {
    @State private var showingDiscoverSheet = false
    
    var body: some View {
        Button(action: {
            showingDiscoverSheet = true
        }) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color(red: 1.0, green: 0.6, blue: 0.0).opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    SwiftUI.Image(systemName: "sparkles")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(red: 1.0, green: 0.6, blue: 0.0))
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text("Discover New Cards")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Explore the latest expansions and find new cards for your collection")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                SwiftUI.Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .sheet(isPresented: $showingDiscoverSheet) {
            CardDiscoverView()
        }
    }
}

// MARK: - Card Discover View
struct CardDiscoverView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var cardService: CardService
    @StateObject private var expansionService = ExpansionService()
    @State private var selectedTCGType: TCGType? = nil
    @State private var searchText = ""
    @State private var searchResults: [CardTemplate] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?
    
    private var filteredCards: [Card] {
        var cards = cardService.userCards
        
        // Filter by TCG type
        if let selectedType = selectedTCGType {
            cards = cards.filter { $0.tcgType == selectedType }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            cards = cards.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        return cards
    }
    
    private var recentSets: [TCGSet] {
        expansionService.recentExpansions.flatMap { $0.sets }.filter { $0.isRecent }.sorted { $0.releaseDate > $1.releaseDate }
    }
    
    // Helper functions for TCG filters
    private func backgroundColorFor(_ tcgType: TCGType?) -> Color {
        guard let tcgType = tcgType else {
            return selectedTCGType == nil ? Color.blue.opacity(0.8) : Color(UIColor.secondarySystemFill)
        }
        return selectedTCGType == tcgType ? tcgType.themeColor.opacity(0.8) : Color(UIColor.secondarySystemFill)
    }
    
    private func textColorFor(_ tcgType: TCGType?) -> Color {
        guard let tcgType = tcgType else {
            return selectedTCGType == nil ? .white : .primary
        }
        return selectedTCGType == tcgType ? .white : .primary
    }
    
    private func iconColorFor(_ tcgType: TCGType?, type: TCGType) -> Color {
        return selectedTCGType == type ? .white : type.themeColor
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                Color(.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Premium Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Discover")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.primary, .blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text("Explore new cards and expansions")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        
                        // Modern Search Bar
                        HStack(spacing: 12) {
                            SwiftUI.Image(systemName: "magnifyingglass")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.secondary)
                            
                            TextField("Search cards, sets...", text: $searchText)
                                .font(.system(size: 16, weight: .medium))
                            
                            if !searchText.isEmpty {
                                Button(action: { searchText = "" }) {
                                    SwiftUI.Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 18))
                                }
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                        
                        if !searchText.isEmpty && searchText.count >= 2 {
                            searchResultsView
                        } else {
                            // TCG Filter
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach([nil] + TCGType.allCases, id: \.self) { tcgType in
                                        Button(action: {
                                            selectedTCGType = tcgType
                                        }) {
                                            HStack(spacing: 6) {
                                                if let type = tcgType {
                                                    SwiftUI.Image(systemName: type.systemIcon)
                                                        .font(.system(size: 14, weight: .semibold))
                                                        .foregroundColor(iconColorFor(tcgType, type: type))
                                                }
                                                
                                                Text(tcgType?.displayName ?? "All")
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundColor(textColorFor(tcgType))
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(
                                                Capsule()
                                                    .fill(backgroundColorFor(tcgType))
                                            )
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            
                            // Featured Expansions (Vertical List)
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("All Expansions")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                }
                                
                                VStack(spacing: 16) {
                                    ForEach(filteredExpansions.prefix(8)) { expansion in
                                        NavigationLink(destination: ExpansionDetailView(expansion: expansion).environmentObject(expansionService)) {
                                            ExpansionRow(expansion: expansion, isButton: false) { }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // Featured Cards
                            if searchText.isEmpty && selectedTCGType == nil && !filteredCards.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Text("Featured Cards")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                    }
                                    
                                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                        ForEach(Array(filteredCards.prefix(6)), id: \.id) { card in
                                            NavigationLink(destination: CardDetailView(card: card, isFromDiscover: false)) {
                                                CompactCardView(card: card)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                }
            }
            .task {
                await expansionService.loadExpansions()
            }
            .onChange(of: searchText) { newValue in
                performSearch(query: newValue)
            }
        }
    }
    
    // Computed properties
    private var filteredExpansions: [Expansion] {
        var expansions = expansionService.expansions
        
        if let selectedType = selectedTCGType {
            expansions = expansions.filter { $0.tcgType == selectedType }
        }
        
        if !searchText.isEmpty {
            expansions = expansions.filter { 
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.sets.contains { $0.setCode.localizedCaseInsensitiveContains(searchText) } ||
                $0.sets.contains { $0.name.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        return expansions
    }
    
    // MARK: - Search Results View
    private var searchResultsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Search Results")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                if isSearching {
                    ProgressView()
                        .scaleEffect(0.8)
                }
                
                Spacer()
                
                Text("\(searchResults.count) results")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            
            if searchResults.isEmpty && !isSearching {
                EmptyStateRow(message: "No cards found")
                    .padding(.horizontal, 20)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(searchResults) { cardTemplate in
                        NavigationLink(destination: CardDetailView(card: cardTemplate.toCard(), isFromDiscover: true)) {
                            SearchCardResultView(cardTemplate: cardTemplate)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
    
    // MARK: - Search Logic
    private func performSearch(query: String) {
        // Cancel previous search task
        searchTask?.cancel()
        
        // Clear results if query is too short
        guard query.count >= 2 else {
            searchResults = []
            isSearching = false
            return
        }
        
        // Debounce search with 0.5 second delay
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                isSearching = true
            }
            
            cardService.searchCardTemplates(query: query) { result in
                DispatchQueue.main.async {
                    isSearching = false
                    switch result {
                    case .success(let cards):
                        searchResults = cards
                    case .failure(let error):
                        print("Search error: \(error.localizedDescription)")
                        searchResults = []
                    }
                }
            }
        }
    }
}

// MARK: - Compact Card View for Featured Section
struct CompactCardView: View {
    let card: Card
    
    var body: some View {
        VStack(spacing: 0) {
            // Card Image
            ZStack {
                CachedAsyncImage(url: URL(string: card.fullImageURL ?? "")) { phase in
                    switch phase {
                    case .empty:
                        Color(.secondarySystemBackground)
                            .overlay(ProgressView())
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Color(.secondarySystemBackground)
                            .overlay(
                                SwiftUI.Image(systemName: card.tcgType?.systemIcon ?? "questionmark.circle")
                                    .font(.system(size: 30))
                                    .foregroundColor(.secondary)
                            )
                    @unknown default:
                        Color(.secondarySystemBackground)
                    }
                }
            }
            .frame(height: 160)
            .clipped()
            
            // Card Info
            VStack(alignment: .leading, spacing: 6) {
                Text(card.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack {
                    Text(card.set ?? "Unknown Set")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if let price = card.marketPrice {
                        Text("€\(String(format: "%.2f", price))")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.green)
                    }
                }
            }
            .padding(12)
            .background(Color(.systemBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Set Card Component
struct SetCard: View {
    let set: TCGSet
    let action: () -> Void
    
    // Dynamic color based on set code or name
    private var cardColor: Color {
        // Use a hash of the set code to generate a consistent color
        let hash = abs(set.setCode.hashValue)
        let hue = Double(hash % 360) / 360.0
        return Color(hue: hue, saturation: 0.6, brightness: 0.8)
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Set Image
                ZStack {
                CachedAsyncImage(url: URL(string: set.logoUrl ?? "")) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(cardColor.opacity(0.3))
                            .frame(height: 100)
                            .overlay(
                                VStack(spacing: 6) {
                                    SwiftUI.Image(systemName: "square.stack.3d.up.fill")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(cardColor)
                                    
                                    Text(set.setCode.uppercased())
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(cardColor)
                                }
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    case .failure(_):
                        RoundedRectangle(cornerRadius: 12)
                            .fill(cardColor.opacity(0.3))
                            .frame(height: 100)
                            .overlay(
                                VStack(spacing: 6) {
                                    SwiftUI.Image(systemName: "square.stack.3d.up.fill")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(cardColor)
                                    
                                    Text(set.setCode.uppercased())
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(cardColor)
                                }
                            )
                    @unknown default:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(cardColor.opacity(0.3))
                            .frame(height: 100)
                            .overlay(
                                VStack(spacing: 6) {
                                    SwiftUI.Image(systemName: "square.stack.3d.up.fill")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(cardColor)
                                    
                                    Text(set.setCode.uppercased())
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(cardColor)
                                }
                            )
                    }
                }                    // Gradient overlay for better text readability
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, .black.opacity(0.3)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Set code badge
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text(set.setCode.uppercased())
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.black.opacity(0.7))
                                .clipShape(Capsule())
                                .padding(6)
                        }
                    }
                }
                .frame(height: 100)
                
                // Set Info
                VStack(spacing: 4) {
                    Text(set.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 8) {
                        HStack(spacing: 2) {
                            SwiftUI.Image(systemName: "square.stack.3d.up.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            
                            Text("\(set.cardCount)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 2) {
                            SwiftUI.Image(systemName: "calendar")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            
                            Text(set.formattedReleaseDate)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: cardColor.opacity(0.3), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(cardColor.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CollectionView()
        .environmentObject(CardService())
}
