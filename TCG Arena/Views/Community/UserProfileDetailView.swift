//
//  UserProfileDetailView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/10/25.
//

import SwiftUI

struct UserProfileDetailView: View {
    let userProfile: UserProfile
    @StateObject private var discoverService = DiscoverService()
    @State private var selectedTab = 0
    @State private var showingCardCollection = false
    @Environment(\.presentationMode) var presentationMode
    
    private let tabs = ["Overview", "Collections", "Decks", "Activity"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Profile Header
                    profileHeader
                    
                    // Tab Selector
                    tabSelector
                    
                    // Tab Content
                    tabContent
                        .padding(.top, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingCardCollection) {
            UserCardCollectionView(userProfile: userProfile)
        }
    }
    
    private var profileHeader: some View {
        VStack(spacing: 20) {
            // Profile Avatar - Centered at top
            ZStack {
                Circle()
                    .fill(.white)
                    .frame(width: 100, height: 100)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                
                Circle()
                    .fill(userProfile.preferredTCG?.themeColor ?? .blue)
                    .frame(width: 92, height: 92)
                
                Text(String(userProfile.displayName.prefix(2)).uppercased())
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.top, 20)
            
            // User Info - Under avatar
            VStack(spacing: 12) {
                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        Text(userProfile.displayName)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                        
                        if userProfile.isVerified {
                            SwiftUI.Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Text("@\(userProfile.username)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                if let bio = userProfile.bio {
                    Text(bio)
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .padding(.horizontal, 24)
                }
                
                // Location
                if let location = userProfile.location {
                    HStack(spacing: 6) {
                        SwiftUI.Image(systemName: "location.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text("\(location.city), \(location.country)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Badges
                if !userProfile.badges.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(userProfile.badges.prefix(5)), id: \.id) { badge in
                                badgeView(badge)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .frame(height: 36)
                    .padding(.bottom, 8)
                }
            }
            .padding(.horizontal, 20)
            
            // Stats Section - Before tabs
            VStack(spacing: 12) {
                Text("Statistics")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                HStack(spacing: 16) {
                    compactStatCard(title: "Level", value: "\(userProfile.level)")
                    
                    // Clickable Cards stat
                    Button {
                        showingCardCollection = true
                    } label: {
                        VStack(spacing: 4) {
                            HStack(spacing: 4) {
                                Text("\(userProfile.stats.totalCards)")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                SwiftUI.Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.blue)
                            }
                            
                            HStack(spacing: 4) {
                                Text("Cards")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                SwiftUI.Image(systemName: "square.stack.3d.up.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.blue)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    
                    compactStatCard(title: "Decks", value: "\(userProfile.stats.totalDecks)")
                    compactStatCard(title: "Wins", value: "\(userProfile.stats.tournamentsWon)")
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    private func badgeView(_ badge: UserBadge) -> some View {
        HStack(spacing: 6) {
            SwiftUI.Image(systemName: badge.iconName)
                .font(.system(size: 12))
            
            Text(badge.name)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(badge.color.color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(badge.color.color.opacity(0.1))
        )
    }
    
    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                    Button {
                        selectedTab = index
                    } label: {
                        VStack(spacing: 8) {
                            Text(tab)
                                .font(.system(size: 16, weight: selectedTab == index ? .semibold : .medium))
                                .foregroundColor(selectedTab == index ? .primary : .secondary)
                            
                            Rectangle()
                                .fill(selectedTab == index ? (userProfile.preferredTCG?.themeColor ?? .blue) : .clear)
                                .frame(height: 2)
                        }
                    }
                    .frame(width: 100)
                }
            }
            .padding(.horizontal, 20)
        }
        .background(Color(.systemBackground))
    }
    
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case 0:
            overviewTab
        case 1:
            collectionsTab
        case 2:
            decksTab
        case 3:
            activityTab
        default:
            overviewTab
        }
    }
    
    private var overviewTab: some View {
        LazyVStack(spacing: 16) {
            // Detailed Stats
            VStack(alignment: .leading, spacing: 12) {
                Text("Statistics")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 20)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    statDetailCard(title: "Cards Collected", value: "\(userProfile.stats.totalCards)")
                    statDetailCard(title: "Decks Created", value: "\(userProfile.stats.totalDecks)")
                    statDetailCard(title: "Tournaments Won", value: "\(userProfile.stats.tournamentsWon)")
                    statDetailCard(title: "Trades Made", value: "\(userProfile.stats.totalTrades)")
                }
                .padding(.horizontal, 20)
            }
            
            // Recent Activity
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Activity")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 20)
                
                LazyVStack(spacing: 8) {
                    ForEach(discoverService.recentActivities.filter { $0.userProfile?.id == userProfile.id }.prefix(5)) { activity in
                        // Simplified activity view to avoid component conflicts
                        HStack {
                            Text("📈")
                            Text(activity.description)
                                .font(.system(size: 14))
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var collectionsTab: some View {
        LazyVStack(spacing: 16) {
            // Collection Summary
            VStack(alignment: .leading, spacing: 12) {
                Text("Collection Summary")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 20)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    collectionCard(tcg: "Pokémon", count: userProfile.stats.totalCards / 3, icon: "⚡", color: .yellow)
                    collectionCard(tcg: "One Piece", count: userProfile.stats.totalCards / 4, icon: "🏴‍☠️", color: .blue)
                    collectionCard(tcg: "Magic", count: userProfile.stats.totalCards / 5, icon: "🔮", color: .purple)
                    collectionCard(tcg: "Yu-Gi-Oh!", count: userProfile.stats.totalCards / 6, icon: "👁️", color: .orange)
                }
                .padding(.horizontal, 20)
            }
            
            // Recent Additions
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Additions")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 20)
                
                LazyVStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        recentCardView(cardName: getRandomCardName(index: index), rarity: getRandomRarity(index: index))
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var decksTab: some View {
        LazyVStack(spacing: 16) {
            // Deck Summary
            VStack(alignment: .leading, spacing: 12) {
                Text("Deck Collection")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 20)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    deckSummaryCard(title: "Total Decks", value: "\(userProfile.stats.totalDecks)", icon: "square.stack.3d.up.fill", color: .blue)
                    deckSummaryCard(title: "Win Rate", value: String(format: "%.1f%%", userProfile.stats.winRate * 100), icon: "chart.line.uptrend.xyaxis", color: .green)
                    deckSummaryCard(title: "Tournaments", value: "\(userProfile.stats.tournamentsWon)", icon: "trophy.fill", color: .yellow)
                    deckSummaryCard(title: "Favorites", value: "3", icon: "heart.fill", color: .red)
                }
                .padding(.horizontal, 20)
            }
            
            // Featured Decks
            VStack(alignment: .leading, spacing: 12) {
                Text("Featured Decks")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 20)
                
                LazyVStack(spacing: 12) {
                    ForEach(0..<userProfile.stats.totalDecks.clamped(to: 1...4), id: \.self) { index in
                        deckCardView(
                            name: getDeckName(index: index, tcg: userProfile.preferredTCG),
                            tcg: userProfile.preferredTCG?.displayName ?? "Mixed",
                            winRate: Double.random(in: 0.6...0.9),
                            matches: Int.random(in: 15...45)
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var activityTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activity Feed")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
                .padding(.horizontal, 20)
            
            LazyVStack(spacing: 8) {
                ForEach(discoverService.recentActivities.filter { $0.userProfile?.id == userProfile.id }.prefix(5)) { activity in
                    // Simplified activity view to avoid component conflicts  
                    HStack {
                        Text("📈")
                        Text(activity.description)
                            .font(.system(size: 14))
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func statDetailCard(title: String, value: String) -> some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private func compactStatCard(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
    }
    
    // MARK: - Helper Functions for Collections
    private func collectionCard(tcg: String, count: Int, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text(icon)
                    .font(.system(size: 20))
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(count)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(tcg)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func recentCardView(cardName: String, rarity: String) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(getRarityColor(rarity).opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(cardName.prefix(1)))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(getRarityColor(rarity))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(cardName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(rarity)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("2h ago")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
    }
    
    // MARK: - Helper Functions for Decks
    private func deckSummaryCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            SwiftUI.Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private func deckCardView(name: String, tcg: String, winRate: Double, matches: Int) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(userProfile.preferredTCG?.themeColor.opacity(0.2) ?? Color.blue.opacity(0.2))
                .frame(width: 50, height: 35)
                .overlay(
                    Text(String(name.prefix(2)).uppercased())
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(userProfile.preferredTCG?.themeColor ?? .blue)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(tcg)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text("\(matches) matches")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f%%", winRate * 100))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(winRate > 0.7 ? .green : winRate > 0.5 ? .orange : .red)
                
                Text("win rate")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    // MARK: - Data Helpers
    private func getRandomCardName(index: Int) -> String {
        let cards = ["Charizard ex", "Pikachu VMAX", "Luffy Gear 5", "Black Lotus", "Blue-Eyes White Dragon"]
        return cards[index % cards.count]
    }
    
    private func getRandomRarity(index: Int) -> String {
        let rarities = ["Ultra Rare", "Secret Rare", "Rare", "Common", "Legendary"]
        return rarities[index % rarities.count]
    }
    
    private func getRarityColor(_ rarity: String) -> Color {
        switch rarity {
        case "Ultra Rare", "Secret Rare", "Legendary": return .purple
        case "Rare": return .blue
        default: return .gray
        }
    }
    
    private func getDeckName(index: Int, tcg: TCGType?) -> String {
        switch tcg {
        case .pokemon: return ["Pikachu Control", "Charizard Aggro", "Mew Combo"][index % 3]
        case .onePiece: return ["Luffy Rush", "Zoro Swords", "Nami Control"][index % 3]
        case .magic: return ["Blue Control", "Red Burn", "Green Ramp"][index % 3]
        case .yugioh: return ["Blue-Eyes", "Dark Magician", "Exodia"][index % 3]
        case .digimon: return ["Agumon Bond", "Gabumon Control", "WarGreymon Aggro"][index % 3]
        case .none: return ["Mixed Deck", "Custom Build", "Experimental"][index % 3]
        }
    }
}

// MARK: - Int Extension for Clamping
extension Int {
    func clamped(to range: ClosedRange<Int>) -> Int {
        return Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - User Card Collection View
struct UserCardCollectionView: View {
    let userProfile: UserProfile
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTCG: TCGType?
    
    private let mockCards: [MockCard] = [
        MockCard(name: "Charizard ex", rarity: "Ultra Rare", tcg: .pokemon, image: "🔥", imageURL: "https://images.pokemontcg.io/sv3pt5/207_hires.png", estimatedValue: 89.99),
        MockCard(name: "Pikachu VMAX", rarity: "Secret Rare", tcg: .pokemon, image: "⚡", imageURL: "https://images.pokemontcg.io/swsh4/188_hires.png", estimatedValue: 45.50),
        MockCard(name: "Luffy Gear 5", rarity: "Leader", tcg: .onePiece, image: "👑", imageURL: nil, estimatedValue: 125.00),
        MockCard(name: "Zoro Three Sword", rarity: "Super Rare", tcg: .onePiece, image: "⚔️", imageURL: nil, estimatedValue: 32.75),
        MockCard(name: "Black Lotus", rarity: "Mythic", tcg: .magic, image: "🌸", imageURL: nil, estimatedValue: 25000.00),
        MockCard(name: "Lightning Bolt", rarity: "Common", tcg: .magic, image: "⚡", imageURL: nil, estimatedValue: 2.50),
        MockCard(name: "Blue-Eyes White Dragon", rarity: "Ultra Rare", tcg: .yugioh, image: "🐉", imageURL: nil, estimatedValue: 78.99),
        MockCard(name: "Dark Magician", rarity: "Rare", tcg: .yugioh, image: "🧙‍♂️", imageURL: nil, estimatedValue: 15.25),
        MockCard(name: "Mew ex", rarity: "Ultra Rare", tcg: .pokemon, image: "💫", imageURL: "https://images.pokemontcg.io/sv3pt5/151_hires.png", estimatedValue: 65.00),
        MockCard(name: "Sanji Black Leg", rarity: "Super Rare", tcg: .onePiece, image: "🦵", imageURL: nil, estimatedValue: 28.50),
        MockCard(name: "Force of Will", rarity: "Rare", tcg: .magic, image: "🌀", imageURL: nil, estimatedValue: 120.00),
        MockCard(name: "Exodia the Forbidden One", rarity: "Ultra Rare", tcg: .yugioh, image: "👹", imageURL: nil, estimatedValue: 95.75)
    ]
    
    private var filteredCards: [MockCard] {
        guard let selectedTCG = selectedTCG else { return mockCards }
        return mockCards.filter { $0.tcg == selectedTCG }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(userProfile.displayName)'s Collection")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("\(mockCards.count) cards total")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    // TCG Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            CollectionTCGFilterButton(tcg: nil, selectedTCG: $selectedTCG, title: "All")
                            CollectionTCGFilterButton(tcg: .pokemon, selectedTCG: $selectedTCG, title: "Pokémon")
                            CollectionTCGFilterButton(tcg: .onePiece, selectedTCG: $selectedTCG, title: "One Piece")
                            CollectionTCGFilterButton(tcg: .magic, selectedTCG: $selectedTCG, title: "Magic")
                            CollectionTCGFilterButton(tcg: .yugioh, selectedTCG: $selectedTCG, title: "Yu-Gi-Oh!")
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 20)
                .background(Color(.systemBackground))
                
                // Cards List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredCards, id: \.name) { card in
                            CardListItemView(card: card)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Supporting Views for Collection
struct MockCard {
    let name: String
    let rarity: String
    let tcg: TCGType
    let image: String
    let imageURL: String?
    let estimatedValue: Double?
}

struct CollectionTCGFilterButton: View {
    let tcg: TCGType?
    @Binding var selectedTCG: TCGType?
    let title: String
    
    var body: some View {
        Button {
            selectedTCG = tcg
        } label: {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(selectedTCG == tcg ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(selectedTCG == tcg ? (tcg?.themeColor ?? .blue) : Color(.systemGray6))
                )
        }
    }
}

struct CardListItemView: View {
    let card: MockCard
    
    var body: some View {
        HStack(spacing: 16) {
            // Card image placeholder with realistic aspect ratio
            AsyncImage(url: URL(string: card.imageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(card.tcg.themeColor.opacity(0.15))
                    .overlay(
                        VStack(spacing: 4) {
                            Text(card.image)
                                .font(.system(size: 28))
                            Text(card.tcg.displayName)
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(card.tcg.themeColor)
                        }
                    )
            }
            .frame(width: 65, height: 90) // Realistic TCG card proportions
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(card.tcg.themeColor.opacity(0.3), lineWidth: 1)
            )
            
            // Card details
            VStack(alignment: .leading, spacing: 6) {
                Text(card.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    Circle()
                        .fill(card.tcg.themeColor)
                        .frame(width: 8, height: 8)
                    
                    Text(card.tcg.displayName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(card.tcg.themeColor)
                }
                
                Text(card.rarity)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(getRarityColor(card.rarity))
                
                if let value = card.estimatedValue {
                    HStack(spacing: 4) {
                        SwiftUI.Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                        
                        Text("$\(value, specifier: "%.2f")")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.green)
                    }
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 0.5)
        )
    }
    
    private func getRarityColor(_ rarity: String) -> Color {
        switch rarity {
        case "Ultra Rare", "Secret Rare", "Mythic", "Leader": return .purple
        case "Super Rare", "Rare": return .blue
        default: return .secondary
        }
    }
}