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
            
            if sortedCards.isEmpty {
                // Empty State
                VStack(spacing: 24) {
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: 120, height: 120)
                        
                        SwiftUI.Image(systemName: "rectangle.portrait.on.rectangle.portrait.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 12) {
                        Text("No Cards Yet")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("This deck is empty. Add cards from the search or scan them to build your deck.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .background(Color(.systemGroupedBackground))
                .transition(.opacity)
            } else {
                // Card List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(sortedCards.enumerated()), id: \.element.cardID) { index, deckCard in
                            NavigationLink(destination: SimpleCardDetailView(cardID: deckCard.cardID, cardName: deckCard.cardName)) {
                                UserDeckCardRowView(
                                    deckCard: deckCard,
                                    showMarketValue: showMarketValues
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.05), value: true)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
                .background(Color(.systemGroupedBackground))
            }
        }
        .navigationTitle(deck.name)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
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

        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
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
            // Deck Info
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 8) {
                    // TCG Icon small
                    ZStack {
                        Circle()
                            .fill(deck.tcgType.themeColor.opacity(0.15))
                            .frame(width: 32, height: 32)
                        
                        SwiftUI.Image(systemName: deck.tcgType.icon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(deck.tcgType.themeColor)
                    }
                    
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
                    
                    Text(deck.formattedDateModified)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if deck.isPublic {
                        HStack(spacing: 4) {
                            SwiftUI.Image(systemName: "globe")
                                .font(.system(size: 11))
                            Text("Public")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .cornerRadius(8)
                    } else {
                        HStack(spacing: 4) {
                            SwiftUI.Image(systemName: "lock.fill")
                                .font(.system(size: 10))
                            Text("Private")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .foregroundColor(.orange)
                        .cornerRadius(8)
                    }
                }
            }
            .padding(16)
        }
        .background(
            ZStack {
                Color(.systemBackground)
                
                // Subtle gradient based on TCG type
                LinearGradient(
                    gradient: Gradient(colors: [
                        deck.tcgType.themeColor.opacity(0.05),
                        Color(.systemBackground)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
        .shadow(
            color: Color.black.opacity(0.03),
            radius: 5,
            x: 0,
            y: 2
        )
    }
}