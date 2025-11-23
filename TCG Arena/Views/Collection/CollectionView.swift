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
    @StateObject private var marketService = MarketDataService()
    @AppStorage("showMarketValues") private var showMarketValues: Bool = true
    @State private var showingAddCard = false
    @State private var selectedTCGType: TCGType? = nil
    @State private var searchText = ""
    @State private var isInitialLoading = true
    @State private var viewMode: ViewMode = .decks
    @State private var selectedDeck: Deck? = nil
    @State private var selectedCard: Card? = nil
    @State private var isDeckActive = false
    @State private var isCardActive = false
    
    enum ViewMode {
        case decks, allCards
    }
    
    var filteredCards: [Card] {
        var cards = cardService.userCards
        
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
                // Modern Header with gradient accent
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("My Decks")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text(viewMode == .decks ? "\(deckService.userDecks.count) decks" : "\(filteredCards.count) cards in collection")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: { showingAddCard = true }) {
                            HStack(spacing: 8) {
                                SwiftUI.Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Add Card")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 8)
                    
                    // View Mode Selector
                    Picker("View Mode", selection: $viewMode) {
                        Text("Decks").tag(ViewMode.decks)
                        Text("All Cards").tag(ViewMode.allCards)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                }
                
                // Modern Search Bar
                VStack(spacing: 0) {
                    HStack {
                        SwiftUI.Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                            .font(.system(size: 16, weight: .medium))
                        
                        TextField(viewMode == .decks ? "Search your decks..." : "Search your collection...", text: $searchText)
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
                
                // Portfolio Card (se abilitato)
                if showMarketValues, let portfolio = marketService.portfolioSummary {
                    PortfolioCard(portfolio: portfolio)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                }
                
                // Modern TCG Filter
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
                
                // Separator line
                Rectangle()
                    .fill(Color(.separator).opacity(0.5))
                    .frame(height: 2)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                
                // Discover Section
                DiscoverInfoBox()
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                
                if viewMode == .decks {
                    if filteredDecks.isEmpty {
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
                                    Text("No Decks Yet")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.primary)
                                
                                    Text("Create your first deck to start collecting cards!")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(nil)
                                }
                            }
                        
                        }
                        .padding(.horizontal, 40)
                        .padding(.vertical, 60)
                    } else {
                        List(filteredDecks) { deck in
                            Button(action: { 
                                selectedDeck = deck
                                isDeckActive = true
                            }) {
                                DeckRowView(deck: deck)
                            }
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                        }
                        .listStyle(PlainListStyle())
                        .background(Color(.systemGroupedBackground))
                    }
                } else {
                    if filteredCards.isEmpty {
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
                    } else {
                        List(filteredCards) { card in
                            Button(action: { 
                                selectedCard = card
                                isCardActive = true
                            }) {
                                CardRowView(card: card, deckService: deckService)
                            }
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                        }
                        .listStyle(PlainListStyle())
                        .background(Color(.systemGroupedBackground))
                    }
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .background(
                Group {
                    if selectedDeck != nil {
                        NavigationLink("", destination: DeckDetailView(deck: selectedDeck!), isActive: Binding(get: { isDeckActive }, set: { isDeckActive = $0; if !$0 { selectedDeck = nil } }))
                    }
                    if selectedCard != nil {
                        NavigationLink("", destination: CardDetailView(card: selectedCard!), isActive: Binding(get: { isCardActive }, set: { isCardActive = $0; if !$0 { selectedCard = nil } }))
                    }
                }
            )
            .navigationBarItems(trailing: 
                Button(action: { showingAddCard = true }) {
                    SwiftUI.Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(TCGTheme.Colors.accent)
                }
            )
            .sheet(isPresented: $showingAddCard) {
                NewAddCardView()
                    .environmentObject(cardService)
                    .environmentObject(deckService)
            }
            .onAppear {
                if showMarketValues {
                    marketService.loadMarketData()
                }
            }
            .onChange(of: showMarketValues) { enabled in
                if enabled {
                    marketService.loadMarketData()
                }
            }
        }
        .background(Color(.systemBackground))
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
}

struct HorizontalCardRowView: View {
    let card: Card
    
    var body: some View {
        HStack(spacing: 16) {
            // Card Image
            if let imageURL = card.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(card.tcgType.themeColor.opacity(0.2))
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
                            .fill(card.tcgType.themeColor.opacity(0.2))
                            .frame(width: 60, height: 84)
                            .overlay(
                                SwiftUI.Image(systemName: card.tcgType.systemIcon)
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(card.tcgType.themeColor)
                            )
                    @unknown default:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(card.tcgType.themeColor.opacity(0.2))
                            .frame(width: 60, height: 84)
                    }
                }
            } else {
                // Placeholder when no image URL
                RoundedRectangle(cornerRadius: 8)
                    .fill(card.tcgType.themeColor.opacity(0.2))
                    .frame(width: 60, height: 84)
                    .overlay(
                        SwiftUI.Image(systemName: card.tcgType.systemIcon)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(card.tcgType.themeColor)
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
            }
            
            Spacer()
            
            // Price and TCG Badge
            VStack(alignment: .trailing, spacing: 8) {
                if let price = card.marketPrice {
                    Text("€\(String(format: "%.2f", price))")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                SwiftUI.Image(systemName: tcgIcon(card.tcgType))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(card.tcgType.themeColor)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(card.tcgType.themeColor.opacity(0.1))
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
    @State private var showingExpansionDetail = false
    @State private var selectedExpansion: Expansion?
    
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
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Discover")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("Explore new cards and expansions")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    // Search Bar
                    HStack {
                        HStack {
                            SwiftUI.Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                                .font(.system(size: 16, weight: .medium))
                            
                            TextField("Search cards by name...", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(.system(size: 16, weight: .medium))
                            
                            if !searchText.isEmpty {
                                Button(action: { searchText = "" }) {
                                    SwiftUI.Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 16, weight: .medium))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(UIColor.systemGray6))
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                    
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
                }
                .padding(.vertical, 16)
                .background(Color(.systemBackground))
                
                // Main Content
                ScrollView {
                    VStack(spacing: 0) {
                        // Recent Sets Section
                        if !recentSets.isEmpty {
                            VStack(spacing: 0) {
                                // Header
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Recent Sets")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.primary)
                                        
                                        Text("Discover the latest card sets")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                                .padding(.bottom, 16)
                                
                                // Carousel
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(recentSets) { set in
                                            SetCard(set: set) {
                                                // For now, just show a placeholder action
                                                // TODO: Navigate to set detail view
                                            }
                                            .frame(width: 160)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.top, 8)
                                    .padding(.bottom, 16)
                                }
                                .padding(.bottom, 32)
                            }
                            .background(Color(.systemBackground))
                        }
                        
                        // Elegant separator
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [
                                    Color.clear, 
                                    Color.blue.opacity(0.15), 
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(height: 1)
                            .padding(.horizontal, 30)
                        
                        // All Expansions Section
                        VStack(spacing: 0) {
                            // Header
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("All Expansions")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.primary)
                                    
                                    Text("Browse by expansion set")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            .padding(.bottom, 16)
                            
                            // Expansions List
                            VStack(spacing: 12) {
                                ForEach(filteredExpansions.prefix(8)) { expansion in
                                    ExpansionRow(expansion: expansion) {
                                        selectedExpansion = expansion
                                        showingExpansionDetail = true
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                            .padding(.bottom, 24)
                        }
                        .background(Color(.systemBackground))
                        
                        // Featured Cards Section
                        if searchText.isEmpty && selectedTCGType == nil && !filteredCards.isEmpty {
                            VStack(spacing: 0) {
                                // Header
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Featured Cards")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.primary)
                                        
                                        Text("Discover popular cards")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                                .padding(.bottom, 16)
                                
                                // Cards Grid
                                let columns = [
                                    GridItem(.flexible(), spacing: 12),
                                    GridItem(.flexible(), spacing: 12)
                                ]
                                
                                LazyVGrid(columns: columns, spacing: 16) {
                                    ForEach(Array(filteredCards.prefix(6)), id: \.id) { card in
                                        NavigationLink(destination: CardDetailView(card: card)) {
                                            CompactCardView(card: card)
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 24)
                            }
                            .background(Color(.systemBackground))
                        }
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                }
            }
            .sheet(isPresented: $showingExpansionDetail) {
                if let expansion = selectedExpansion {
                    ExpansionDetailView(expansion: expansion)
                }
            }
            .task {
                await expansionService.loadExpansions()
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
}

// MARK: - Compact Card View for Featured Section
struct CompactCardView: View {
    let card: Card
    
    var body: some View {
        VStack(spacing: 12) {
            // Card Image
            AsyncImage(url: URL(string: card.imageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 12)
                    .fill(card.tcgType.themeColor.opacity(0.2))
                    .overlay(
                        VStack(spacing: 6) {
                            SwiftUI.Image(systemName: card.tcgType.systemIcon)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(card.tcgType.themeColor)
                            
                            Text(card.cardNumber ?? "")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(card.tcgType.themeColor)
                        }
                    )
            }
            .frame(height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Card Info
            VStack(spacing: 6) {
                Text(card.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(card.tcgType.themeColor)
                        .frame(width: 6, height: 6)
                    
                    Text(card.tcgType.displayName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(card.tcgType.themeColor)
                }
                
                if let expansion = card.expansion {
                    ExpansionBadge(expansion: expansion) {
                        // Handle expansion tap
                    }
                }
                
                if let price = card.marketPrice {
                    Text("€\(price, specifier: "%.2f")")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.green)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: card.tcgType.themeColor.opacity(0.2), radius: 6, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(card.tcgType.themeColor.opacity(0.3), lineWidth: 1)
        )
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
                    AsyncImage(url: URL(string: set.imageURL ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } placeholder: {
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
                    
                    // Gradient overlay for better text readability
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
