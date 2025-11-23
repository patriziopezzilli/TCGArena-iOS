import SwiftUI
import Foundation

struct UserDeckListView: View {
    let deck: Deck
    @StateObject private var marketService = MarketDataService()
    @AppStorage("showMarketValues") private var showMarketValues: Bool = true
    @State private var selectedTab = 0
    @State private var sortBy: SortOption = .name
    
    enum SortOption: String, CaseIterable {
        case name = "Name"
        case quantity = "Quantity"
        case rarity = "Rarity"
        
        var title: String { rawValue }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            UserDeckListHeader(deck: deck, sortBy: $sortBy)
            
            List {
                ForEach(sortedCards, id: \.cardID) { deckCard in
                    NavigationLink(destination: SimpleCardDetailView(cardID: deckCard.cardID, cardName: deckCard.cardName)) {
                        UserDeckCardRowView(
                            deckCard: deckCard,
                            showMarketValue: showMarketValues
                        )
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
        .navigationTitle(deck.name)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var sortedCards: [Deck.DeckCard] {
        return sortCards(deck.cards)
    }
    
    private func sortCards(_ cards: [Deck.DeckCard]) -> [Deck.DeckCard] {
        switch sortBy {
        case .name:
            return cards.sorted { $0.cardName < $1.cardName }
        case .quantity:
            return cards.sorted { $0.quantity > $1.quantity }
        case .rarity:
            return cards.sorted { $0.cardName < $1.cardName } // Fallback to name since we don't have rarity in Deck.DeckCard
        }
    }
}

struct UserDeckListHeader: View {
    let deck: Deck
    @Binding var sortBy: UserDeckListView.SortOption
    
    var body: some View {
        VStack(spacing: 16) {
            // Deck Info (senza nome duplicato)
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let description = deck.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Text("\(deck.totalCards) cards")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // TCG Type Badge
                HStack(spacing: 4) {
                    SwiftUI.Image(systemName: deck.tcgType.icon)
                        .font(.system(size: 11, weight: .semibold))
                    
                    Text(deck.tcgType.displayName)
                        .font(.system(size: 12, weight: .semibold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(deck.tcgType.themeColor.opacity(0.15))
                )
                .foregroundColor(deck.tcgType.themeColor)
            }
            
            // Sort Controls
            HStack {
                Text("Sort by:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("Sort", selection: $sortBy) {
                    ForEach(UserDeckListView.SortOption.allCases, id: \.self) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: 1)
    }
}

struct UserDeckCardRowView: View {
    let deckCard: Deck.DeckCard
    let showMarketValue: Bool
    @StateObject private var marketService = MarketDataService()
    
    private var cardPrice: Double? {
        return marketService.getPriceForCard(deckCard.cardName.lowercased().replacingOccurrences(of: " ", with: "-"))?.currentPrice
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Quantity indicator
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 24, height: 24)
                
                Text("\(deckCard.quantity)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(deckCard.cardName)
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

// MARK: - SimpleCardDetailView for simple card ID (Collection-style)
struct SimpleCardDetailView: View {
    let cardID: String
    let cardName: String
    @StateObject private var marketService = MarketDataService()
    @AppStorage("showMarketValues") private var showMarketValues = true
    
    // Detect TCG type from card name (basic detection)
    private var detectedTCGType: TCGType {
        let lowerName = cardName.lowercased()
        if lowerName.contains("pikachu") || lowerName.contains("pokemon") || lowerName.contains("charizard") {
            return .pokemon
        } else if lowerName.contains("luffy") || lowerName.contains("shanks") || lowerName.contains("piece") {
            return .onePiece
        } else if lowerName.contains("lightning") || lowerName.contains("island") || lowerName.contains("forest") {
            return .magic
        } else {
            return .yugioh
        }
    }
    
    private var cardPrice: CardPrice? {
        return marketService.getPriceForCard(cardName.lowercased().replacingOccurrences(of: " ", with: "-"))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Clean Header with TCG Icon (same style as CardDetailView)
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(detectedTCGType.themeColor)
                            .frame(width: 50, height: 50)
                        
                        SwiftUI.Image(systemName: detectedTCGType.systemIcon)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(cardName)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        Text(detectedTCGType.displayName)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(detectedTCGType.themeColor)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                // Card Image Placeholder - Portrait aspect ratio
                RoundedRectangle(cornerRadius: 16)
                    .fill(detectedTCGType.themeColor.opacity(0.1))
                    .aspectRatio(2.5/3.5, contentMode: .fit)
                    .overlay(
                        VStack(spacing: 12) {
                            SwiftUI.Image(systemName: detectedTCGType.systemIcon)
                                .font(.system(size: 60, weight: .bold))
                                .foregroundColor(detectedTCGType.themeColor.opacity(0.6))
                            
                            Text("Card Image")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(detectedTCGType.themeColor.opacity(0.6))
                        }
                    )
                    .padding(.horizontal, 40)
                
                // Market Value Section (same style as CardDetailView)
                if showMarketValues, let price = cardPrice {
                    InfoCard(title: "Market Value") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Current Price")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)
                                    
                                    Text(price.formattedPrice)
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.primary)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Weekly Change")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)
                                    
                                    Text(price.formattedChange)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(price.priceChangeColor)
                                }
                            }
                        }
                    }
                }
                
                Spacer()
            }
        }
        .navigationTitle(cardName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - UserDeckRowView for deck list display
struct UserDeckRowView: View {
    let deck: Deck
    @StateObject private var marketService = MarketDataService()
    
    var body: some View {
        HStack(spacing: 0) {
            // Colored stripe on the left
            deck.tcgType.themeColor
                .frame(width: 4)
            
            // Deck Info
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 8) {
                    // TCG Icon small
                    SwiftUI.Image(systemName: deck.tcgType.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(deck.tcgType.themeColor)
                    
                    Text(deck.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                }
                
                HStack(spacing: 6) {
                    Text("\(deck.totalCards) cards")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    Text(deck.dateModified.formatted(.relative(presentation: .named)))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if deck.isPublic {
                        SwiftUI.Image(systemName: "globe")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                    } else {
                        SwiftUI.Image(systemName: "lock")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding(.leading, 12)
            .padding(.vertical, 14)
            .padding(.trailing, 12)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(
                    color: Color.black.opacity(0.06),
                    radius: 8,
                    x: 0,
                    y: 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray6), lineWidth: 1)
        )
    }
}