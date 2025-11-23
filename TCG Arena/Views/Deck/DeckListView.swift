import SwiftUI
import Foundation

struct DeckListView: View {
    let deck: ProDeck
    @Environment(\.dismiss) private var dismiss
    @StateObject private var marketService = MarketDataService()
    @AppStorage("showMarketValues") private var showMarketValues: Bool = true
    
    enum SortOption: String, CaseIterable {
        case quantity = "Quantity"
        case manaCost = "Mana Cost"
        case rarity = "Rarity"
        
        var icon: String {
            switch self {
            case .quantity: return "number"
            case .manaCost: return "circle.fill"
            case .rarity: return "star.fill"
            }
        }
    }
    
    struct RarityCount: Identifiable {
        let id = UUID()
        let rarity: Rarity
        let count: Int
    }
    
    private var rarityBreakdown: [RarityCount] {
        let grouped = Dictionary(grouping: deck.cards ?? []) { $0.cardTemplate.rarity }
        return grouped.map { RarityCount(rarity: $0.key, count: $0.value.reduce(0) { $0 + $1.quantity }) }
            .sorted { $0.count > $1.count }
    }
    
    @State private var selectedTab = 0
    @State private var sortBy: SortOption = .quantity
    @State private var showingSortOptions = false
    @State private var selectedCard: ProDeckCard? = nil
    @State private var isCardActive = false
    
    private var mainboardCards: [ProDeckCard] {
        return deck.cards?.filter { $0.section == "main" } ?? []
    }
    
    private var sideboardCards: [ProDeckCard] {
        return deck.cards?.filter { $0.section == "sideboard" } ?? []
    }
    
    private var sortedMainboard: [ProDeckCard] {
        return sortCards(mainboardCards)
    }
    
    private var sortedSideboard: [ProDeckCard] {
        return sortCards(sideboardCards)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            DeckListHeader(deck: deck)
            
            // Tabs
            Picker("View", selection: $selectedTab) {
                Text("Mainboard (\(mainboardCards.count))").tag(0)
                if !sideboardCards.isEmpty {
                    Text("Sideboard (\(sideboardCards.count))").tag(1)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            // Sort Options
            HStack {
                Button(action: { showingSortOptions = true }) {
                    HStack(spacing: 6) {
                        SwiftUI.Image(systemName: sortBy.icon)
                        Text("Sort by \(sortBy.rawValue)")
                        SwiftUI.Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text("\(selectedTab == 0 ? mainboardCards.reduce(0) { $0 + $1.quantity } : sideboardCards.reduce(0) { $0 + $1.quantity }) cards")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            
            // Content
            TabView(selection: $selectedTab) {
                // Mainboard
                DeckCardListView(
                    cards: sortedMainboard,
                    marketService: marketService,
                    showMarketValues: showMarketValues,
                    onSelect: { 
                        selectedCard = $0
                        isCardActive = true
                    }
                )
                .tag(0)
                
                // Sideboard
                if !sideboardCards.isEmpty {
                    DeckCardListView(
                        cards: sortedSideboard,
                        marketService: marketService,
                        showMarketValues: showMarketValues,
                        onSelect: { 
                            selectedCard = $0
                            isCardActive = true
                        }
                    )
                    .tag(1)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
        .navigationTitle(deck.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            trailing: Button("Edit") {
                // TODO: Implementa editing
            }
        )
        .background(
            Group {
                if selectedCard != nil {
                    NavigationLink("", destination: SimpleProCardDetailView(deckCard: selectedCard!), isActive: Binding(get: { isCardActive }, set: { isCardActive = $0; if !$0 { selectedCard = nil } }))
                }
            }
        )
        .actionSheet(isPresented: $showingSortOptions) {
            ActionSheet(
                title: Text("Sort Cards"),
                buttons: SortOption.allCases.map { option in
                    .default(Text(option.rawValue)) {
                        sortBy = option
                    }
                } + [.cancel()]
            )
        }
        .onAppear {
            if showMarketValues {
                marketService.loadMarketData()
            }
        }
    }
    
    private func sortCards(_ cards: [ProDeckCard]) -> [ProDeckCard] {
        switch sortBy {
        case .quantity:
            return cards.sorted { $0.quantity > $1.quantity }
        case .manaCost:
            return cards.sorted { ($0.cardTemplate.manaCost ?? 0) < ($1.cardTemplate.manaCost ?? 0) }
        case .rarity:
            return cards.sorted { $0.cardTemplate.rarity.rawValue < $1.cardTemplate.rarity.rawValue }
        }
    }
}

struct DeckListHeader: View {
    let deck: ProDeck
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                // TCG Icon
                ZStack {
                    Circle()
                        .fill(deck.tcgType.themeColor)
                        .frame(width: 50, height: 50)
                    
                    SwiftUI.Image(systemName: deck.tcgType.systemIcon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(deck.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("by \(deck.author)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(deck.totalCards)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("cards")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if !deck.description.isEmpty {
                Text(deck.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Tournament Info
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tournament: \(deck.tournament)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Placement: \(deck.placement)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal, 20)
    }
}

struct DeckCardListView: View {
    let cards: [ProDeckCard]
    let marketService: MarketDataService
    let showMarketValues: Bool
    let onSelect: (ProDeckCard) -> Void
    
    var body: some View {
        List(cards) { deckCard in
            Button(action: { onSelect(deckCard) }) {
                SimpleDeckCardRowView(
                    deckCard: deckCard,
                    showMarketValue: showMarketValues
                )
            }
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 0))
        }
        .listStyle(PlainListStyle())
    }
}

struct DeckStatsView: View {
    let deck: ProDeck
    
    var manaCurve: [(cost: Int, count: Int)] {
        let curve = deck.manaCurve
        return Array(0...10).map { cost in
            (cost: cost, count: curve[cost] ?? 0)
        }.filter { $0.count > 0 }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Basic Stats
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    StatCard(title: "Total Cards", value: "\(deck.totalCards)", icon: "rectangle.stack", color: .blue)
                    StatCard(title: "Unique Cards", value: "\(deck.cards?.count ?? 0)", icon: "square.stack.3d.up", color: .green)
                    StatCard(title: "Tournament", value: deck.tournament, icon: "calendar", color: .purple)
                }
                .padding(.horizontal, 20)
                
                // Mana Curve (se applicabile)
                if deck.tcgType == .magic && !manaCurve.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Mana Curve")
                            .font(.headline)
                            .padding(.horizontal, 20)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .bottom, spacing: 8) {
                                ForEach(manaCurve, id: \.cost) { item in
                                    VStack(spacing: 4) {
                                        Rectangle()
                                            .fill(deck.tcgType.themeColor)
                                            .frame(width: 24, height: CGFloat(item.count * 8))
                                            .cornerRadius(4)
                                        
                                        Text("\(item.count)")
                                            .font(.caption2)
                                            .fontWeight(.medium)
                                        
                                        Text("\(item.cost)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
                
                // Rarity Breakdown
                // Removed to fix compilation errors
            }
            .padding(.bottom, 32)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            SwiftUI.Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}


struct SimpleDeckCardRowView: View {
    let deckCard: ProDeckCard
    let showMarketValue: Bool
    @StateObject private var marketService = MarketDataService()
    
    private var cardPrice: Double? {
        return marketService.getPriceForCard(deckCard.cardTemplate.name.lowercased().replacingOccurrences(of: " ", with: "-"))?.currentPrice
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Quantity indicator
            ZStack {
                Circle()
                    .fill(deckCard.cardTemplate.tcgType.themeColor)
                    .frame(width: 24, height: 24)
                
                Text("\(deckCard.quantity)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(deckCard.cardTemplate.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("Qty: \(deckCard.quantity)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if showMarketValue, let price = cardPrice {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("$\(price, specifier: "%.2f")")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                    
                    Text("each")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            SwiftUI.Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}
