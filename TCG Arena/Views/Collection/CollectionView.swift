import SwiftUI
import Foundation
// Import for MarketDataService and PortfolioSummary
import TCG_Arena
import SkeletonUI

// MARK: - Import From Decks View
struct ImportFromDecksView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var cardService: CardService
    @EnvironmentObject var deckService: DeckService
    @State private var selectedCards: Set<Int64> = []
    @State private var isImporting = false

    private var decksWithCards: [Deck] {
        deckService.userDecks.filter { !$0.cards.isEmpty }
    }

    private var allCardsFromDecks: [(deck: Deck, card: Deck.DeckCard)] {
        var result: [(deck: Deck, card: Deck.DeckCard)] = []
        for deck in decksWithCards {
            for card in deck.cards {
                result.append((deck: deck, card: card))
            }
        }
        return result
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Text("Importa Carte nella Collezione")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)

                    Text("Seleziona le carte dai tuoi mazzi da aggiungere alla collezione")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

                if decksWithCards.isEmpty {
                    // No decks with cards
                    VStack(spacing: 24) {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 120, height: 120)

                            SwiftUI.Image(systemName: "rectangle.stack")
                                .font(.system(size: 50, weight: .medium))
                                .foregroundColor(.gray)
                        }

                        VStack(spacing: 12) {
                            Text("Nessuna Carta nei Mazzi")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)

                            Text("Add cards to your decks first, then you can import them to your collection.")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 40)
                } else {
                    // List of cards from decks
                    List {
                        ForEach(decksWithCards, id: \.id) { deck in
                            Section(header: Text(deck.name)) {
                                ForEach(deck.cards, id: \.cardId) { deckCard in
                                    HStack {
                                        // Card Image
                                        if let imageURL = URL(string: deckCard.cardImageUrl ?? "") {
                                            CachedAsyncImage(url: imageURL) { phase in
                                                switch phase {
                                                case .empty:
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .fill(Color.gray.opacity(0.2))
                                                        .frame(width: 50, height: 70)
                                                        .overlay(ProgressView())
                                                case .success(let image):
                                                    image
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                        .frame(width: 50, height: 70)
                                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                                case .failure:
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .fill(Color.gray.opacity(0.2))
                                                        .frame(width: 50, height: 70)
                                                        .overlay(
                                                            SwiftUI.Image(systemName: "photo")
                                                                .foregroundColor(.gray)
                                                        )
                                                @unknown default:
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .fill(Color.gray.opacity(0.2))
                                                        .frame(width: 50, height: 70)
                                                }
                                            }
                                        } else {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.gray.opacity(0.2))
                                                .frame(width: 50, height: 70)
                                                .overlay(
                                                    SwiftUI.Image(systemName: "photo")
                                                        .foregroundColor(.gray)
                                                )
                                        }

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(deckCard.cardName)
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.primary)

                                            Text("Quantità: \(deckCard.quantity)")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.secondary)
                                        }

                                        Spacer()

                                        // Checkbox
                                        SwiftUI.Image(systemName: selectedCards.contains(deckCard.cardId) ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 24, weight: .medium))
                                            .foregroundColor(selectedCards.contains(deckCard.cardId) ? .blue : .gray)
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        if selectedCards.contains(deckCard.cardId) {
                                            selectedCards.remove(deckCard.cardId)
                                        } else {
                                            selectedCards.insert(deckCard.cardId)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") {
                        dismiss()
                    }
                }

                if !decksWithCards.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: importSelectedCards) {
                            if isImporting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Importa (\(selectedCards.count))")
                                    .fontWeight(.semibold)
                            }
                        }
                        .disabled(selectedCards.isEmpty || isImporting)
                    }
                }
            }
        }
    }

    private func importSelectedCards() {
        guard !selectedCards.isEmpty else { return }

        isImporting = true

        // Find the selected cards and import them
        let cardsToImport = allCardsFromDecks.filter { selectedCards.contains($0.card.cardId) }

        var importedCount = 0
        let totalCount = cardsToImport.count

        for (deck, deckCard) in cardsToImport {
            // Add each card to collection with default condition
            cardService.addCardToCollection(cardTemplateId: Int(deckCard.cardId), condition: .nearMint, quantity: deckCard.quantity) { result in
                switch result {
                case .success(let updatedDeck):
                    // Card successfully added to collection deck
                    importedCount += 1
                    if importedCount == totalCount {
                        // All cards imported
                        DispatchQueue.main.async {
                            self.isImporting = false
                            self.dismiss()
                        }
                    }
                case .failure(let error):
                    ToastManager.shared.showError("Failed to import card \(deckCard.cardName): \(error.localizedDescription)")
                    importedCount += 1
                    if importedCount == totalCount {
                        DispatchQueue.main.async {
                            self.isImporting = false
                            self.dismiss()
                        }
                    }
                }
            }
        }
    }
}

struct CollectionView: View {
    @EnvironmentObject var cardService: CardService
    @EnvironmentObject var deckService: DeckService
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var marketService: MarketDataService
    @State private var showingCreateDeck = false
    @State private var showingAddCard = false
    @State private var selectedTCGType: TCGType? = nil
    @State private var searchText = ""
    @State private var isInitialLoading = true
    @State private var viewMode: ViewMode = .lists
    @State private var isLoadingCards = false
    @State private var selectedCard: Card? = nil
    @State private var isCardActive = false
    @State private var isLoadingDecks = true
    @State private var showingImportFromDecks = false
    @State private var userCards: [Card] = [] // Personal collection cards
    @State private var enrichedAllCards: [Card] = [] // Cards from all decks (enriched)
    @State private var hasAppeared = false // For initial appearance animation
    @State private var isAddCardButtonPressed = false
    @State private var isCreateDeckButtonPressed = false
    @State private var showingTCGRules = false
    @State private var selectedRulesTCG: TCGType? = nil
    @AppStorage("dismissedTCGRulesBanners") private var dismissedBannersData: Data = Data()
    @State private var isHeaderCollapsed = false // For collapsible header on scroll
    @State private var animatedDeckIds: Set<Int64> = [] // Track decks that have animated in
    @State private var animatedCardIds: Set<String> = [] // Track cards that have animated in
    @State private var showAddMenu = false // For custom Flutter-style menu
    @State private var showingSearch = false // NEW: Toggle search/filter bar

    enum ViewMode {
        case lists, allCards, rules
    }
    
    var filteredCards: [Card] {
        var cards: [Card]

        if viewMode == .allCards {
            // Show all cards from all decks with enrichment
            cards = enrichedAllCards
        } else {
            // Show only cards from user's personal collection
            cards = userCards
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
    
    // Separate count calculations for the picker
    var listsCount: Int {
        var count = deckService.userDecks.count

        // Filter by TCG type
        if let tcgType = selectedTCGType {
            count = deckService.userDecks.filter { $0.tcgType == tcgType }.count
        }

        // Filter by search text
        if !searchText.isEmpty {
            count = deckService.userDecks.filter { $0.name.localizedCaseInsensitiveContains(searchText) }.count
        }

        return count
    }

    var allCardsCount: Int {
        var count = enrichedAllCards.count

        // Apply TCG type filter
        if let tcgType = selectedTCGType {
            count = enrichedAllCards.filter { $0.tcgType == tcgType }.count
        }

        // Apply search text filter
        if !searchText.isEmpty {
            var filteredCount = 0
            for card in enrichedAllCards {
                // Apply TCG type filter first
                var shouldInclude = true
                if let tcgType = selectedTCGType {
                    shouldInclude = card.tcgType == tcgType
                }
                // Then apply search filter
                if shouldInclude && card.name.localizedCaseInsensitiveContains(searchText) {
                    filteredCount += 1
                }
            }
            count = filteredCount
        }

        return count
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
    
    private func loadUserCards() {
        isLoadingCards = true
        cardService.getUserCardCollection { result in
            DispatchQueue.main.async {
                self.isLoadingCards = false
                switch result {
                case .success(let cards):
                    // Cards are already enriched by getUserCardCollection
                    self.userCards = cards
                case .failure(_):
                    print("fail")
                }
            }
        }
    }


    private func loadEnrichedAllCards() {
        let group = DispatchGroup()
        let serialQueue = DispatchQueue(label: "com.tcgarena.cardEnrichment")
        var cardsByTemplateId: [Int64: (card: Card, totalQuantity: Int, deckNames: [String])] = [:]

        for deck in deckService.userDecks {
            for deckCard in deck.cards {
                let templateId = deckCard.cardId
                
                // Controlla se la carta esiste già in modo thread-safe
                serialQueue.sync {
                    if var existing = cardsByTemplateId[templateId] {
                        // Aggiorna quantità e deck names
                        existing.totalQuantity += deckCard.quantity
                        if !existing.deckNames.contains(deck.name) {
                            existing.deckNames.append(deck.name)
                        }
                        cardsByTemplateId[templateId] = existing
                    } else {
                        // Prima volta che vediamo questa carta - segna come in elaborazione
                        cardsByTemplateId[templateId] = (Card(
                            id: nil,
                            templateId: templateId,
                            name: deckCard.cardName,
                            rarity: .common,
                            condition: .nearMint,
                            imageURL: deckCard.cardImageUrl,
                            isFoil: false,
                            quantity: deckCard.quantity,
                            ownerId: 1,
                            createdAt: Date(),
                            updatedAt: Date(),
                            tcgType: deck.tcgType,
                            set: nil,
                            cardNumber: nil,
                            expansion: nil,
                            marketPrice: nil,
                            description: nil
                        ), deckCard.quantity, [deck.name])
                        
                        group.enter()
                        // Create basic card from deck card
                        guard let deckId = deck.id else {
                            group.leave()
                            return
                        }
                        let basicCard = cardService.convertDeckCardToCard(deckCard, deckId: deckId)

                        // Enrich with template data
                        cardService.enrichCardWithTemplateData(basicCard) { result in
                            serialQueue.async {
                                switch result {
                                case .success(var enrichedCard):
                                    // Aggiorna con la carta arricchita
                                    if let existing = cardsByTemplateId[templateId] {
                                        enrichedCard.deckNames = existing.deckNames
                                        cardsByTemplateId[templateId] = (enrichedCard, existing.totalQuantity, existing.deckNames)
                                    }
                                case .failure(let error):
                                    print("Failed to enrich card \(deckCard.cardName): \(error.localizedDescription)")
                                    // Mantieni la carta base già inserita
                                }
                                group.leave()
                            }
                        }
                    }
                }
            }
        }

        group.notify(queue: .main) {
            // Converti il dizionario in array di carte
            var finalCards: [Card] = []
            serialQueue.sync {
                for (_, value) in cardsByTemplateId {
                    var card = value.card
                    card.deckNames = value.deckNames
                    finalCards.append(card)
                }
            }
            
            // Sort cards by name for consistent ordering
            self.enrichedAllCards = finalCards.sorted { $0.name < $1.name }
            print("🔍 CollectionView: Loaded \(finalCards.count) unique cards from all decks")
        }
    }

    // Helper function to update a card in local state for instant UI feedback
    private func updateCardInLocalState(_ updatedCard: Card) {
        // Update in userCards array
        if let index = userCards.firstIndex(where: { $0.id == updatedCard.id }) {
            userCards[index] = updatedCard
        }
        
        // Update in enrichedAllCards array
        if let index = enrichedAllCards.firstIndex(where: { $0.id == updatedCard.id }) {
            enrichedAllCards[index] = updatedCard
        }
        
        print("✅ CollectionView: Updated card '\(updatedCard.name)' in local state")
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                headerView
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : -10)
                
                // Discover Section (Conditional part of Search)
                if showingSearch && !isHeaderCollapsed && viewMode != .rules {
                    discoverSectionView
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Search bar (Conditional)
                if showingSearch && !isHeaderCollapsed && viewMode != .rules {
                    searchBarView
                        .opacity(hasAppeared ? 1 : 0)
                        .offset(y: hasAppeared ? 0 : -8)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                // TCG filter (Conditional)
                if showingSearch && viewMode != .rules {
                    tcgFilterView
                        .opacity(hasAppeared ? 1 : 0)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Tab Selector - Below filters as in Flutter
                tabSelectorView
                    .padding(.bottom, 8)
                
                // TCG Rules Info Banner
                if viewMode != .rules {
                    tcgRulesBannerView
                }
                
                // Content - different handling for rules tab
                if viewMode == .rules {
                    rulesGridView
                } else {
                    contentView
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.3), value: hasAppeared)
            .navigationTitle("")
            .navigationBarHidden(true)
            .background(cardNavigationLink)
            .overlay(
                ZStack {
                    if showAddMenu {
                        customAddMenuOverlay
                    }
                }
            )
            .sheet(isPresented: $showingCreateDeck) {
                CreateDeckView(userId: authService.currentUserId ?? 0)
                    .environmentObject(deckService)
            }
            .sheet(isPresented: $showingAddCard) {
                NewAddCardView()
                    .environmentObject(cardService)
                    .environmentObject(deckService)
            }
            .sheet(item: $selectedRulesTCG) { tcgType in
                TCGRulesView(tcgType: tcgType)
            }
            .onAppear {
                onAppearAction()
                // Trigger appearance animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    hasAppeared = true
                }
            }
            .task(taskAction)
            .refreshable {
                await performRefresh()
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Collezione")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
            }

            Spacer()

            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showingSearch.toggle()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(Color(.systemGray6))
                        .frame(width: 40, height: 40)
                    
                    SwiftUI.Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(showingSearch ? .blue : .primary)
                }
            }
            .padding(.trailing, 8)

            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showAddMenu.toggle()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(Color.primary)
                        .frame(width: 40, height: 40)
                        .shadow(color: Color.primary.opacity(0.3), radius: 8, x: 0, y: 2)
                    
                    SwiftUI.Image(systemName: showAddMenu ? "xmark" : "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(showAddMenu ? 90 : 0))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }

    private var customAddMenuOverlay: some View {
        ZStack {
            // Background dim/tap area
            Color.black.opacity(0.01)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showAddMenu = false
                    }
                }
            
            VStack {
                HStack {
                    Spacer()
                    VStack(alignment: .leading, spacing: 0) {
                        // Add Card Item
                        Button(action: {
                            showAddMenu = false
                            showingAddCard = true
                        }) {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.1))
                                        .frame(width: 32, height: 32)
                                    SwiftUI.Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 18))
                                }
                                Text("Aggiungi Carta")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        
                        Divider()
                            .padding(.horizontal, 12)
                        
                        // Create List Item
                        Button(action: {
                            showAddMenu = false
                            showingCreateDeck = true
                        }) {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.green.opacity(0.1))
                                        .frame(width: 32, height: 32)
                                    SwiftUI.Image(systemName: "plus.square.fill")
                                        .foregroundColor(.green)
                                        .font(.system(size: 18))
                                }
                                Text("Crea Lista")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
                    )
                    .frame(width: 200)
                    .padding(.top, 65) // Adjust based on header height
                    .padding(.trailing, 20)
                }
                Spacer()
            }
        }
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.9, anchor: .topTrailing)),
            removal: .opacity.combined(with: .scale(scale: 0.9, anchor: .topTrailing))
        ))
    }

    private var tabSelectorView: some View {
        // View Mode Selector - Compact Design
        HStack(spacing: 0) {
            CompactTabButton(
                icon: "rectangle.stack.fill",
                label: "Liste",
                count: listsCount,
                isSelected: viewMode == .lists
            ) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewMode = .lists
                }
            }
            
            CompactTabButton(
                icon: "square.grid.2x2.fill",
                label: "Carte",
                count: allCardsCount,
                isSelected: viewMode == .allCards
            ) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewMode = .allCards
                }
            }
            
            CompactTabButton(
                icon: "book.fill",
                label: "Regole",
                count: nil,
                isSelected: viewMode == .rules
            ) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewMode = .rules
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal, 20)
    }

    private var searchBarView: some View {
        VStack(spacing: 0) {
            HStack {
                SwiftUI.Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 16, weight: .medium))

                TextField(viewMode == .lists ? "Cerca nelle liste..." : viewMode == .allCards ? "Cerca le tue carte..." : "Cerca nella collezione...", text: $searchText)
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
                    .fill(Color(.systemGray6))
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
    }

    private var portfolioCardView: some View {
        Group {
            if let portfolio = marketService.portfolioSummary {
                PortfolioCard(portfolio: portfolio)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95)).combined(with: .offset(y: -10)),
                        removal: .opacity
                    ))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: portfolio.totalValue)
            }
        }
    }

    private var tcgFilterView: some View {
        // Get TCGs that user actually has content for (cards in decks)
        let tcgsWithContent: [TCGType] = {
            var tcgSet = Set<TCGType>()
            for deck in deckService.userDecks {
                tcgSet.insert(deck.tcgType)
            }
            return Array(tcgSet).sorted { $0.displayName < $1.displayName }
        }()
        
        let availableTCGs: [TCGType?] = tcgsWithContent.isEmpty 
            ? [nil] + TCGType.allCases 
            : [nil] + tcgsWithContent
        
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(availableTCGs, id: \.self) { tcgType in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTCGType = tcgType
                        }
                    }) {
                        HStack(spacing: 8) {
                            if let type = tcgType {
                                TCGIconView(tcgType: type, size: 15, color: iconColorFor(tcgType, type: type))
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
                        )
                        .scaleEffect(selectedTCGType == tcgType ? 1.05 : 1.0)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 20)
        .padding(.bottom, 12)
    }
    
    // MARK: - TCG Rules Banner
    private var dismissedBanners: Set<String> {
        get {
            guard let decoded = try? JSONDecoder().decode(Set<String>.self, from: dismissedBannersData) else {
                return []
            }
            return decoded
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                dismissedBannersData = encoded
            }
        }
    }
    
    private func isDismissed(_ tcgType: TCGType) -> Bool {
        dismissedBanners.contains(tcgType.rawValue)
    }
    
    private func dismissBanner(for tcgType: TCGType) {
        var dismissed = dismissedBanners
        dismissed.insert(tcgType.rawValue)
        if let encoded = try? JSONEncoder().encode(dismissed) {
            dismissedBannersData = encoded
        }
    }
    
    @ViewBuilder
    private var tcgRulesBannerView: some View {
        if let tcgType = selectedTCGType, !isDismissed(tcgType) {
            TCGRulesInfoBanner(
                tcgType: tcgType,
                onDismiss: {
                    withAnimation(.easeOut(duration: 0.3)) {
                        dismissBanner(for: tcgType)
                    }
                },
                onLearnMore: {
                    selectedRulesTCG = tcgType
                    showingTCGRules = true
                }
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .move(edge: .top)),
                removal: .opacity.combined(with: .scale(scale: 0.9))
            ))
        }
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
            .padding(.bottom, 12)
    }

    private var contentView: some View {
        ZStack {
            if viewMode == .lists {
                if isLoadingDecks {
                    // Custom rectangular skeleton for decks
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(0..<5, id: \.self) { _ in
                                DeckRowSkeletonView()
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                } else if filteredDecks.isEmpty {
                    emptyDecksView
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    decksListView
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .leading)),
                            removal: .opacity.combined(with: .move(edge: .trailing))
                        ))
                }
            } else if viewMode == .allCards {
                if isLoadingCards {
                    // Custom rectangular skeleton for cards
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(0..<5, id: \.self) { _ in
                                CardRowSkeletonView()
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                } else if filteredCards.isEmpty {
                    emptyCardsView
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    cardsListView
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity.combined(with: .move(edge: .leading))
                        ))
                }
            } else if viewMode == .rules {
                rulesGridView
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .trailing)),
                        removal: .opacity.combined(with: .move(edge: .leading))
                    ))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewMode)
    }
    
    // MARK: - Rules Grid View
    private var rulesGridView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 12) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Regolamenti TCG")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Scopri le regole di ogni gioco di carte collezionabili")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                // Rules cards
                ForEach(TCGType.allCases, id: \.self) { tcgType in
                    RulesListCard(tcgType: tcgType) {
                        selectedRulesTCG = tcgType
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
    }

    private var emptyDecksView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 120, height: 120)

                SwiftUI.Image(systemName: "rectangle.stack")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundColor(.blue)
            }
            .scaleEffect(1.0)
            .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1), value: isLoadingDecks)

            VStack(spacing: 12) {
                Text("Nessuna Lista")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)

                Text("Crea la tua prima lista per iniziare a collezionare!")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            .opacity(1.0)
            .animation(.easeOut(duration: 0.4).delay(0.2), value: isLoadingDecks)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(.horizontal, 40)
    }

    private var decksListView: some View {
        List {
            ForEach(Array(filteredDecks.enumerated()), id: \.element.id) { index, deck in
                ZStack {
                    NavigationLink(destination: DeckDetailView(deck: deck)) {
                        EmptyView()
                    }
                    .opacity(0)

                    DeckRowView(deck: deck)
                        .opacity(animatedDeckIds.contains(deck.id ?? 0) ? 1.0 : 0.0)
                        .offset(y: animatedDeckIds.contains(deck.id ?? 0) ? 0 : 30)
                        .scaleEffect(animatedDeckIds.contains(deck.id ?? 0) ? 1.0 : 0.95)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .onAppear {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.05)) {
                                if let deckId = deck.id {
                                    animatedDeckIds.insert(deckId)
                                }
                            }
                        }
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(PlainListStyle())
        .scrollIndicators(.hidden)
        .background(Color(.systemBackground))
        .onChange(of: filteredDecks.count) { _ in
            // Reset animations when deck list changes significantly (e.g., after refresh)
            // to enable re-animation
        }
        .simultaneousGesture(
            DragGesture().onChanged { value in
                let verticalMovement = value.translation.height
                withAnimation(.easeInOut(duration: 0.25)) {
                    // Collapse header when scrolling down, expand when scrolling up
                    if verticalMovement < -20 && !isHeaderCollapsed {
                        isHeaderCollapsed = true
                    } else if verticalMovement > 20 && isHeaderCollapsed {
                        isHeaderCollapsed = false
                    }
                }
            }
        )
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
                .transition(.opacity.combined(with: .scale(scale: 0.8)))

                VStack(spacing: 12) {
                    Text(viewMode == .allCards ? "Nessuna Carta nei Mazzi" : "Nessuna Carta nella Collezione")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)

                    Text(viewMode == .allCards ?
                        "I tuoi mazzi sono vuoti.\nAggiungi carte ai mazzi per vederle qui." :
                        "Your personal collection is empty.\nAdd cards from the Discover section or import from your decks.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
                .transition(.opacity.combined(with: .offset(y: 10)))

                // Show import option only for collection view
                if viewMode != .allCards && hasCardsInDecks() {
                    Button(action: {
                        showingImportFromDecks = true
                    }) {
                        HStack(spacing: 8) {
                            SwiftUI.Image(systemName: "arrow.down.circle")
                            Text("Importa dai Mazzi")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: viewMode)

        }
        .padding(.horizontal, 40)
        .padding(.vertical, 60)
        .sheet(isPresented: $showingImportFromDecks) {
            ImportFromDecksView()
                .environmentObject(cardService)
                .environmentObject(deckService)
        }
    }



    private var cardsListView: some View {
        List {
            if isLoadingCards {
                // Show skeleton cards while loading
                ForEach(0..<8, id: \.self) { index in
                    CardRowSkeletonView()
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                        .listRowBackground(Color.clear)
                }
            } else {
                ForEach(Array(filteredCards.enumerated()), id: \.element.id) { index, card in
                    let cardId = card.id.map { String($0) } ?? ""
                    ZStack {
                        NavigationLink(destination: CardDetailView(card: card, isFromDiscover: false) { updatedCard in
                            // Update local state immediately for instant UI feedback
                            self.updateCardInLocalState(updatedCard)
                            // Then reload from backend to ensure consistency
                            self.loadUserCards()
                        }) {
                            EmptyView()
                        }
                        .opacity(0)

                        CardRowView(card: card, deckService: deckService)
                            .opacity(animatedCardIds.contains(cardId) ? 1.0 : 0.0)
                            .offset(y: animatedCardIds.contains(cardId) ? 0 : 15)
                            .scaleEffect(animatedCardIds.contains(cardId) ? 1.0 : 0.96)
                            .onAppear {
                                // Limit stagger delay to first 10 items for performance
                                let delay = min(Double(index), 10.0) * 0.04
                                withAnimation(.spring(response: 0.45, dampingFraction: 0.75).delay(delay)) {
                                    animatedCardIds.insert(cardId)
                                }
                            }
                    }
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                    .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(PlainListStyle())
        .scrollIndicators(.hidden)
        .background(Color(.systemGroupedBackground))
        .animation(.easeInOut(duration: 0.3), value: isLoadingCards)
        .simultaneousGesture(
            DragGesture().onChanged { value in
                let verticalMovement = value.translation.height
                withAnimation(.easeInOut(duration: 0.25)) {
                    // Collapse header when scrolling down, expand when scrolling up
                    if verticalMovement < -20 && !isHeaderCollapsed {
                        isHeaderCollapsed = true
                    } else if verticalMovement > 20 && isHeaderCollapsed {
                        isHeaderCollapsed = false
                    }
                }
            }
        )
    }

    private var cardNavigationLink: some View {
        Group {
            if selectedCard != nil {
                NavigationLink("", destination: CardDetailView(card: selectedCard!, isFromDiscover: false) { updatedCard in
                    // Update local state immediately for instant UI feedback
                    self.updateCardInLocalState(updatedCard)
                    selectedCard = updatedCard
                    // Then reload from backend to ensure consistency
                    self.loadUserCards()
                }, isActive: Binding(get: { isCardActive }, set: { isCardActive = $0; if !$0 { selectedCard = nil } }))
            }
        }
    }

    private func onAppearAction() {
        marketService.loadMarketData()

        // Always refresh user decks and cards when appearing
        if let userId = authService.currentUserId {
            deckService.refreshUserDecks(userId: userId) { result in
                DispatchQueue.main.async {
                    self.isLoadingDecks = false
                    // Load enriched cards immediately after decks are loaded
                    self.loadEnrichedAllCards()
                }
                switch result {
                case .success(let decks):
                    // Handle success silently
                    break
                case .failure(let error):
                    // Handle error silently
                    break
                }
            }
        } else {
            isLoadingDecks = false
            // Load enriched cards even if no userId (should not happen)
            loadEnrichedAllCards()
        }

        // Always load user card collection
        loadUserCards()
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

    private func performRefresh() async {
        // Haptic feedback when refresh starts
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Show skeleton while refreshing (don't clear data, just show loading state)
        await MainActor.run {
            // Only show skeleton if we're in lists mode to avoid flicker
            if viewMode == .lists {
                isLoadingDecks = true
            } else {
                isLoadingCards = true
            }
            // Reset animated IDs for fresh animation when data arrives
            animatedDeckIds.removeAll()
            animatedCardIds.removeAll()
        }
        
        // Refresh market data
        marketService.loadMarketData()

        // Always refresh both decks and cards to keep them synchronized
        if let userId = authService.currentUserId {
            await withCheckedContinuation { continuation in
                deckService.refreshUserDecks(userId: userId) { result in
                    DispatchQueue.main.async {
                        // Hide skeleton with smooth transition
                        withAnimation(.easeOut(duration: 0.3)) {
                            self.isLoadingDecks = false
                        }
                        // Reload enriched cards after decks are refreshed
                        self.loadEnrichedAllCards()
                    }
                    switch result {
                    case .success:
                        print("🔄 CollectionView: Decks refreshed successfully")
                    case .failure(let error):
                        print("🔴 CollectionView: Failed to refresh decks: \(error.localizedDescription)")
                    }
                    continuation.resume()
                }
            }
        } else {
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.3)) {
                    isLoadingDecks = false
                }
            }
        }

        // Refresh user card collection
        await withCheckedContinuation { continuation in
            loadUserCards()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.3)) {
                    self.isLoadingCards = false
                }
                continuation.resume()
            }
        }
    }
    
    // MARK: - Data Synchronization Helpers
    private func reloadAllData() {
        // Force complete reload of both user cards and enriched cards
        loadUserCards()
        if let userId = authService.currentUserId {
            deckService.refreshUserDecks(userId: userId) { _ in }
        }
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



    private func hasCardsInDecks() -> Bool {
        return deckService.userDecks.contains { !$0.cards.isEmpty }
    }
}

struct CardRowSkeletonView: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Card Thumbnail Skeleton
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(width: 50, height: 70)

            VStack(alignment: .leading, spacing: 4) {
                // Header with TCG type badge skeleton
                HStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray4))
                        .frame(width: 60, height: 20)
                    Spacer()
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray4))
                        .frame(width: 40, height: 20)
                }

                // Card Name Skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray4))
                    .frame(height: 14)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray4))
                    .frame(width: 120, height: 14)

                // Set and Number Skeleton
                HStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray4))
                        .frame(width: 80, height: 12)

                    Spacer()

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray4))
                        .frame(width: 30, height: 12)
                }

                // Condition bar skeleton
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(.systemGray4))
                    .frame(height: 4)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
        )
    }
}

struct DeckRowSkeletonView: View {
    var body: some View {
        HStack(spacing: 16) {
            // Deck icon skeleton
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray5))
                .frame(width: 60, height: 60)
            
            VStack(alignment: .leading, spacing: 8) {
                // Deck name skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray4))
                    .frame(width: 150, height: 18)
                
                // TCG type and card count
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray4))
                        .frame(width: 70, height: 22)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray4))
                        .frame(width: 60, height: 14)
                }
                
                // Date skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 100, height: 12)
            }
            
            Spacer()
            
            // Chevron skeleton
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray5))
                .frame(width: 10, height: 16)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
        )
    }
}

struct ExpansionRowSkeletonView: View {
    var body: some View {
        HStack(spacing: 16) {
            // Expansion image skeleton
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray5))
                .frame(width: 60, height: 60)
            
            VStack(alignment: .leading, spacing: 8) {
                // Expansion title skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray4))
                    .frame(width: 180, height: 18)
                
                // TCG type badge skeleton
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray4))
                    .frame(width: 80, height: 22)
                
                // Sets count skeleton
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(width: 60, height: 14)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(width: 80, height: 14)
                }
            }
            
            Spacer()
            
            // Chevron skeleton
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray5))
                .frame(width: 10, height: 16)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
        )
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
                                Group {
                                    if let tcgType = card.tcgType {
                                        TCGIconView(tcgType: tcgType, size: 24, color: tcgType.themeColor)
                                    } else {
                                        SwiftUI.Image(systemName: "questionmark.circle")
                                            .font(.system(size: 24, weight: .semibold))
                                            .foregroundColor(Color.gray)
                                    }
                                }
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
                        Group {
                            if let tcgType = card.tcgType {
                                TCGIconView(tcgType: tcgType, size: 24, color: tcgType.themeColor)
                            } else {
                                SwiftUI.Image(systemName: "questionmark.circle")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(Color.gray)
                            }
                        }
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
                
                // Rarity and Deck Info
                HStack(spacing: 12) {
                    // Rarity
                    HStack(spacing: 4) {
                        ForEach(0..<rarityStars(card.rarity), id: \.self) { _ in
                            SwiftUI.Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(rarityColor(card.rarity))
                        }
                    }
                    
                    // Deck/List Info (replacing condition)
                    if let deckNames = card.deckNames, !deckNames.isEmpty {
                        HStack(spacing: 4) {
                            SwiftUI.Image(systemName: "rectangle.stack.fill")
                                .font(.system(size: 10))
                            Text(deckNames.first ?? "")
                                .font(.system(size: 11, weight: .medium))
                                .lineLimit(1)
                            if deckNames.count > 1 {
                                Text("+\(deckNames.count - 1)")
                                    .font(.system(size: 10, weight: .bold))
                            }
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.1))
                        )
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
                
                if let tcgType = card.tcgType {
                    TCGIconView(tcgType: tcgType, size: 12, color: tcgType.themeColor)
                } else {
                    SwiftUI.Image(systemName: "questionmark.circle")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Discover Info Box
struct DiscoverInfoBox: View {
    @State private var showingDiscoverSheet = false
    @EnvironmentObject private var authService: AuthService
    
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
                    Text("Scopri Nuove Carte")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Esplora le ultime espansioni e trova nuove carte per la tua collezione")
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
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator).opacity(0.5), lineWidth: 1.2)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 20)
        .sheet(isPresented: $showingDiscoverSheet) {
            CardDiscoverView()
                .environmentObject(authService)
        }
    }
}

// MARK: - Card Discover View
struct CardDiscoverView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var cardService: CardService
    @EnvironmentObject var authService: AuthService
    @StateObject private var expansionService = ExpansionService()
    @StateObject private var marketService = MarketDataService() // Needed for SetDetailView
    @State private var selectedTCGType: TCGType? = nil
    @State private var searchText = ""
    @State private var searchResults: [CardTemplate] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?
    
    private var filteredCards: [Card] {
        // CardDiscoverView should load cards from search, not from user collection
        // For now, return empty array since this view is for discovering new cards
        []
    }
    
    private var recentSets: [TCGSet] {
        expansionService.recentExpansions.flatMap { $0.sets }.filter { $0.isRecent }.sorted { $0.releaseDate > $1.releaseDate }
    }
    
    // Helper functions for TCG filters
    private func backgroundColorFor(_ tcgType: TCGType?) -> Color {
        guard let tcgType = tcgType else {
            return selectedTCGType == nil ? Color.primary : Color(.systemGray6)
        }
        return selectedTCGType == tcgType ? tcgType.themeColor : Color(.systemGray6)
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
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Scopri")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.primary)
            
            Text("Esplora nuove carte ed espansioni")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 60)
    }
    
    private var searchBarView: some View {
        HStack(spacing: 12) {
            SwiftUI.Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.secondary)
            
            TextField("Cerca carte, set...", text: $searchText)
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
    }
    
    private var contentView: some View {
        if !searchText.isEmpty && searchText.count >= 2 {
            AnyView(searchResultsView)
        } else {
            AnyView(mainContentView)
        }
    }
    
    private var mainContentView: some View {
        Group {
            tcgFilterView
            featuredExpansionsView
            featuredCardsView
        }
    }
    
    private var tcgFilterView: some View {
        // Show only favorite TCGs if user has some, otherwise show all
        let availableTCGs: [TCGType?] = {
            let favorites = authService.favoriteTCGTypes
            if favorites.isEmpty {
                return [nil] + TCGType.allCases
            } else {
                return [nil] + favorites
            }
        }()
        
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(availableTCGs, id: \.self) { tcgType in
                    Button(action: {
                        selectedTCGType = tcgType
                    }) {
                        HStack(spacing: 6) {
                            if let type = tcgType {
                                TCGIconView(tcgType: type, size: 14, color: iconColorFor(tcgType, type: type))
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
    
    private var featuredExpansionsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                
                if expansionService.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if expansionService.isLoading && filteredExpansions.isEmpty {
                // Skeleton loading view
                VStack(spacing: 16) {
                    ForEach(0..<5, id: \.self) { _ in
                        ExpansionRowSkeletonView()
                    }
                }
            } else if filteredExpansions.isEmpty {
                EmptyStateRow(message: "Nessuna espansione trovata")
            } else {
                VStack(spacing: 16) {
                    ForEach(filteredExpansions) { expansion in
                        if let firstSet = expansion.sets.first, expansion.sets.count == 1 {
                            NavigationLink(destination: SetDetailView(set: firstSet).environmentObject(marketService)) {
                                ExpansionRow(expansion: expansion, isButton: false) { }
                            }
                        } else {
                            NavigationLink(destination: ExpansionDetailView(expansion: expansion).environmentObject(expansionService)) {
                                ExpansionRow(expansion: expansion, isButton: false) { }
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var featuredCardsView: some View {
        Group {
            if searchText.isEmpty && selectedTCGType == nil && !filteredCards.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Carte in Evidenza")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(Array(filteredCards.prefix(6)), id: \.id) { card in
                            NavigationLink(destination: CardDetailView(card: card, isFromDiscover: true)) {
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
    
    private var closeButtonView: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: {
                    dismiss()
                }) {
                    SwiftUI.Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(12)
                        .background(
                            Circle()
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        )
                }
                .padding(.top, 16)
                .padding(.trailing, 20)
            }
            Spacer()
        }
    }
    
    // Computed properties for filtering and search
    private var filteredExpansions: [Expansion] {
        var expansions = expansionService.expansions
        
        // Filter by user's favorite TCGs (fallback to all if none set)
        let favorites = authService.favoriteTCGTypes
        if !favorites.isEmpty {
            expansions = expansions.filter { favorites.contains($0.tcgType) }
        }
        
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
                Text("Risultati Ricerca")
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
                EmptyStateRow(message: "Nessuna carta trovata")
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
                        ToastManager.shared.showError("Errore ricerca: \(error.localizedDescription)")
                        searchResults = []
                    }
                }
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                Color(.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        headerView
                        searchBarView
                        contentView
                    }
                    .padding(.bottom, 32)
                }
                
                closeButtonView
            }
            .navigationBarHidden(true)
            .task {
                await expansionService.loadExpansions()
            }
            .onAppear {
                // Ensure favorites are loaded from currentUser on view appear
                authService.loadFavoritesFromUser()
            }
            .onChange(of: searchText) { newValue in
                performSearch(query: newValue)
            }
        }
    }
    
    struct CompactCardView: View {
        let card: Card
        
        private var cardImageView: some View {
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
                                Group {
                                    if let tcgType = card.tcgType {
                                        TCGIconView(tcgType: tcgType, size: 30, color: .secondary)
                                    } else {
                                        SwiftUI.Image(systemName: "questionmark.circle")
                                            .font(.system(size: 30))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            )
                    @unknown default:
                        Color(.secondarySystemBackground)
                    }
                }
            }
            .frame(height: 160)
            .clipped()
        }
        
        private var cardInfoView: some View {
            VStack(alignment: .leading, spacing: 6) {
                Text(card.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack {
                    Text(card.set ?? "Set Sconosciuto")
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
        
        var body: some View {
            VStack(spacing: 0) {
                cardImageView
                cardInfoView
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
        
        private var setImageView: some View {
            ZStack {
                CachedAsyncImage(url: URL(string: set.logoUrl ?? "")) { phase in
                    switch phase {
                    case .empty:
                        setPlaceholderView
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    case .failure(_):
                        setPlaceholderView
                    @unknown default:
                        setPlaceholderView
                    }
                }
                // Gradient overlay for better text readability
                LinearGradient(
                    gradient: Gradient(colors: [.clear, .black.opacity(0.3)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Set code badge
                setCodeBadge
            }
            .frame(height: 100)
        }
        
        private var setPlaceholderView: some View {
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
        
        private var setCodeBadge: some View {
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
        
        private var setInfoView: some View {
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
        
        var body: some View {
            Button(action: action) {
                VStack(spacing: 12) {
                    setImageView
                    setInfoView
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
}
