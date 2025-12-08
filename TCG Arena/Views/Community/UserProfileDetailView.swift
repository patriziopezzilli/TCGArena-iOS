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
    @StateObject private var deckService = DeckService()
    @State private var selectedTab = 0
    @State private var showingCardCollection = false
    @State private var userDecks: [Deck] = []
    @State private var isLoadingDecks = false
    @State private var userActivities: [UserActivity] = []
    @State private var isLoadingActivities = false
    @Environment(\.presentationMode) var presentationMode
    
    // Computed card count from loaded decks (more accurate than cached stats)
    private var totalCardsCount: Int {
        userDecks.reduce(0) { total, deck in
            total + deck.cards.reduce(0) { cardTotal, card in
                cardTotal + card.quantity
            }
        }
    }
    
    // Computed deck count from loaded decks
    private var totalDecksCount: Int {
        userDecks.count
    }
    
    private let tabs = ["Overview", "Decks", "Activity"]
    
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
                    Button("Chiudi") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                loadUserData()
            }
        }
        .sheet(isPresented: $showingCardCollection) {
            UserCardCollectionView(userProfile: userProfile)
        }
    }
    
    private func loadUserData() {
        // Load user's public decks
        // userProfile.id is a String, convert to Int64
        guard let userId = Int64(userProfile.id) else { return }
        
        isLoadingDecks = true
        deckService.loadUserDecks(userId: userId, saveToCache: false) { result in
            DispatchQueue.main.async {
                isLoadingDecks = false
                switch result {
                case .success(let decks):
                    // Filter to show only lista type decks (not system Collection/Wishlist)
                    userDecks = decks.filter { $0.deckType == .lista }
                case .failure(let error):
                    print("Failed to load user decks: \(error)")
                }
            }
        }
        
        // Load user's recent activities from backend
        isLoadingActivities = true
        discoverService.getUserActivities(userId: userId, limit: 10) { result in
            DispatchQueue.main.async {
                isLoadingActivities = false
                switch result {
                case .success(let activities):
                    userActivities = activities
                case .failure(let error):
                    print("Failed to load user activities: \(error)")
                }
            }
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
                                Text("\(totalCardsCount)")
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
                    
                    compactStatCard(title: "Decks", value: "\(totalDecksCount)")
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
            decksTab
        case 2:
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
                    statDetailCard(title: "Cards Collected", value: "\(totalCardsCount)")
                    statDetailCard(title: "Decks Created", value: "\(totalDecksCount)")
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
                
                if isLoadingActivities {
                    // Loading skeleton
                    VStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.systemGray5))
                                .frame(height: 60)
                        }
                    }
                    .padding(.horizontal, 20)
                } else if userActivities.isEmpty {
                    // No activities
                    HStack {
                        SwiftUI.Image(systemName: "clock")
                            .foregroundColor(.secondary)
                        Text("Nessuna attività recente")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal, 20)
                } else {
                    // Show real activities from backend
                    LazyVStack(spacing: 8) {
                        ForEach(userActivities.prefix(5)) { activity in
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(activityColor(for: activity.activityType).opacity(0.2))
                                        .frame(width: 36, height: 36)
                                    SwiftUI.Image(systemName: activityIcon(for: activity.activityType))
                                        .foregroundColor(activityColor(for: activity.activityType))
                                        .font(.system(size: 14))
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(activity.description)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.primary)
                                        .lineLimit(2)
                                    
                                    Text(formatActivityDate(activity.timestamp))
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
    
    // MARK: - Activity Helpers
    
    private func activityIcon(for type: String) -> String {
        switch type {
        case "DECK_CREATED": return "rectangle.stack.fill.badge.plus"
        case "DECK_UPDATED": return "pencil.circle.fill"
        case "DECK_DELETED": return "trash.fill"
        case "CARD_ADDED_TO_COLLECTION": return "plus.circle.fill"
        case "CARD_REMOVED_FROM_COLLECTION": return "minus.circle.fill"
        case "REWARD_REDEEMED": return "gift.fill"
        case "POINTS_EARNED": return "star.fill"
        case "USER_REGISTERED": return "person.badge.plus"
        case "PROFILE_UPDATED": return "person.fill.checkmark"
        default: return "clock.fill"
        }
    }
    
    private func activityColor(for type: String) -> Color {
        switch type {
        case "DECK_CREATED": return .blue
        case "DECK_UPDATED": return .orange
        case "DECK_DELETED": return .red
        case "CARD_ADDED_TO_COLLECTION": return .green
        case "CARD_REMOVED_FROM_COLLECTION": return .red
        case "REWARD_REDEEMED": return .purple
        case "POINTS_EARNED": return .yellow
        case "USER_REGISTERED": return .blue
        case "PROFILE_UPDATED": return .teal
        default: return .gray
        }
    }
    
    private func formatActivityDate(_ dateString: String) -> String {
        // Try to parse ISO date format
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            let relativeFormatter = RelativeDateTimeFormatter()
            relativeFormatter.unitsStyle = .abbreviated
            return relativeFormatter.localizedString(for: date, relativeTo: Date())
        }
        
        // Fallback: try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: dateString) {
            let relativeFormatter = RelativeDateTimeFormatter()
            relativeFormatter.unitsStyle = .abbreviated
            return relativeFormatter.localizedString(for: date, relativeTo: Date())
        }
        
        return dateString
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
                Text("Deck")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 20)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    deckSummaryCard(title: "Total Deck", value: "\(userDecks.count)", icon: "square.stack.3d.up.fill", color: .blue)
                    deckSummaryCard(title: "Tornei Vinti", value: "\(userProfile.stats.tournamentsWon)", icon: "trophy.fill", color: .yellow)
                }
                .padding(.horizontal, 20)
            }
            
            // User's Decks - Real Data
            VStack(alignment: .leading, spacing: 12) {
                Text("I suoi Deck")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 20)
                
                if isLoadingDecks {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                } else if userDecks.isEmpty {
                    VStack(spacing: 12) {
                        SwiftUI.Image(systemName: "square.stack.3d.up.slash")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("Nessun deck pubblico")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(userDecks) { deck in
                            realDeckCardView(deck: deck)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
    
    private func realDeckCardView(deck: Deck) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(deck.tcgType.themeColor.opacity(0.2))
                .frame(width: 50, height: 35)
                .overlay(
                    Text(String(deck.name.prefix(2)).uppercased())
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(deck.tcgType.themeColor)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(deck.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(deck.tcgType.displayName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text("\(deck.cards.count) carte")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private var activityTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Attività Recenti")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
                .padding(.horizontal, 20)
            
            if isLoadingActivities {
                // Loading skeleton
                VStack(spacing: 8) {
                    ForEach(0..<5, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray5))
                            .frame(height: 60)
                    }
                }
                .padding(.horizontal, 20)
            } else if userActivities.isEmpty {
                // Empty State
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.1))
                            .frame(width: 80, height: 80)
                        
                        SwiftUI.Image(systemName: "clock.badge.questionmark")
                            .font(.system(size: 35))
                            .foregroundColor(.orange.opacity(0.6))
                    }
                    
                    VStack(spacing: 6) {
                        Text("Nessuna attività")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("Le attività recenti appariranno qui")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                // Show all activities with proper formatting
                LazyVStack(spacing: 8) {
                    ForEach(userActivities) { activity in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(activityColor(for: activity.activityType).opacity(0.2))
                                    .frame(width: 40, height: 40)
                                SwiftUI.Image(systemName: activityIcon(for: activity.activityType))
                                    .foregroundColor(activityColor(for: activity.activityType))
                                    .font(.system(size: 16))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(activity.description)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                                    .lineLimit(2)
                                
                                Text(formatActivityDate(activity.timestamp))
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 20)
            }
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
        case .dragonBallSuper, .dragonBallFusion: return ["Goku Rush", "Vegeta Control", "Frieza Aggro"][index % 3]
        case .fleshAndBlood: return ["Bravo Aggro", "Rhinar Smash", "Prism Control"][index % 3]
        case .lorcana: return ["Mickey Tempo", "Elsa Control", "Stitch Aggro"][index % 3]
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
    @StateObject private var deckService = DeckService()
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTCG: TCGType?
    @State private var displayCards: [DisplayCard] = []
    @State private var isLoading = true
    
    // Wrapper struct to include TCG type with each card
    struct DisplayCard: Identifiable {
        let id: String
        let card: Deck.DeckCard
        let tcgType: TCGType
    }
    
    private var filteredCards: [DisplayCard] {
        guard let selectedTCG = selectedTCG else { return displayCards }
        return displayCards.filter { $0.tcgType == selectedTCG }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Collezione di \(userProfile.displayName)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("\(displayCards.count) carte")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button {
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            SwiftUI.Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // TCG Filter
                    if !displayCards.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                CollectionTCGFilterButton(tcg: nil, selectedTCG: $selectedTCG, title: "Tutti")
                                CollectionTCGFilterButton(tcg: .pokemon, selectedTCG: $selectedTCG, title: "Pokémon")
                                CollectionTCGFilterButton(tcg: .onePiece, selectedTCG: $selectedTCG, title: "One Piece")
                                CollectionTCGFilterButton(tcg: .magic, selectedTCG: $selectedTCG, title: "Magic")
                                CollectionTCGFilterButton(tcg: .yugioh, selectedTCG: $selectedTCG, title: "Yu-Gi-Oh!")
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.vertical, 20)
                .background(Color(.systemBackground))
                
                // Content
                if isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                    Spacer()
                } else if displayCards.isEmpty {
                    // Empty State
                    Spacer()
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 100, height: 100)
                            
                            SwiftUI.Image(systemName: "rectangle.stack.badge.minus")
                                .font(.system(size: 45))
                                .foregroundColor(.blue.opacity(0.6))
                        }
                        
                        VStack(spacing: 8) {
                            Text("Nessuna carta")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("Questo utente non ha ancora\naggiunto carte alla sua collezione")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(40)
                    Spacer()
                } else {
                    // Cards List
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredCards) { displayCard in
                                RealCardListItemView(displayCard: displayCard)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                loadUserCards()
            }
        }
    }
    
    private func loadUserCards() {
        guard let userId = Int64(userProfile.id) else {
            isLoading = false
            return
        }
        
        isLoading = true
        deckService.loadUserDecks(userId: userId, saveToCache: false) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let decks):
                    // Collect all cards from all decks with TCG type
                    var allCards: [DisplayCard] = []
                    for deck in decks where deck.deckType == .lista {
                        for card in deck.cards {
                            let displayCard = DisplayCard(
                                id: "\(deck.id ?? 0)-\(card.cardId)",
                                card: card,
                                tcgType: deck.tcgType
                            )
                            allCards.append(displayCard)
                        }
                    }
                    displayCards = allCards
                case .failure(let error):
                    print("Failed to load user cards: \(error)")
                }
            }
        }
    }
}

// MARK: - Real Card List Item View
struct RealCardListItemView: View {
    let displayCard: UserCardCollectionView.DisplayCard
    
    // Compose proper image URL
    private var cardImageURL: String? {
        guard let baseUrl = displayCard.card.cardImageUrl, !baseUrl.isEmpty else { return nil }
        // If URL already has /high.webp, use as-is
        if baseUrl.contains("/high.webp") {
            return baseUrl
        }
        // Otherwise append /high.webp
        return "\(baseUrl)/high.webp"
    }
    
    // Get rarity color
    private func rarityColor(for rarity: String?) -> Color {
        guard let rarity = rarity?.lowercased() else { return .secondary }
        switch rarity {
        case "secret rare", "ultra rare", "mythic rare", "leader", "special art":
            return .purple
        case "super rare", "rare", "art rare":
            return .blue
        case "common", "uncommon":
            return .secondary
        default:
            return .orange
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Card image with proper URL composition
            AsyncImage(url: URL(string: cardImageURL ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure(_):
                    placeholderView
                case .empty:
                    placeholderView
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.6)
                        )
                @unknown default:
                    placeholderView
                }
            }
            .frame(width: 65, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(displayCard.tcgType.themeColor.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            
            // Card details
            VStack(alignment: .leading, spacing: 8) {
                Text(displayCard.card.cardName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                // Badges row
                HStack(spacing: 8) {
                    // TCG Badge
                    HStack(spacing: 4) {
                        Circle()
                            .fill(displayCard.tcgType.themeColor)
                            .frame(width: 8, height: 8)
                        Text(displayCard.tcgType.displayName)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(displayCard.tcgType.themeColor)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(displayCard.tcgType.themeColor.opacity(0.1))
                    )
                    
                    // Rarity Badge (if available)
                    if let rarity = displayCard.card.rarity, !rarity.isEmpty {
                        HStack(spacing: 4) {
                            SwiftUI.Image(systemName: "star.fill")
                                .font(.system(size: 8))
                                .foregroundColor(rarityColor(for: rarity))
                            Text(rarity)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(rarityColor(for: rarity))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(rarityColor(for: rarity).opacity(0.1))
                        )
                    }
                }
                
                // Quantity
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        SwiftUI.Image(systemName: "number.square.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Text("x\(displayCard.card.quantity)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    
                    // Set name if available
                    if let setName = displayCard.card.setName, !setName.isEmpty {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(setName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            // Chevron
            SwiftUI.Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 0.5)
        )
    }
    
    private var placeholderView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(displayCard.tcgType.themeColor.opacity(0.15))
            .overlay(
                VStack(spacing: 4) {
                    SwiftUI.Image(systemName: displayCard.tcgType.systemIcon)
                        .font(.system(size: 24))
                        .foregroundColor(displayCard.tcgType.themeColor)
                    Text(displayCard.tcgType.displayName)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(displayCard.tcgType.themeColor)
                }
            )
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
    
    // Computed property per ottenere l'URL completo dell'immagine
    var fullImageURL: String? {
        guard let baseUrl = imageURL else { return nil }
        // Se l'URL è già completo (contiene "/high.webp"), restituiscilo così com'è
        if baseUrl.contains("/high.webp") {
            return baseUrl
        }
        // Altrimenti, aggiungi qualità "high" e formato "webp"
        return "\(baseUrl)/high.webp"
    }
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
            AsyncImage(url: URL(string: card.fullImageURL ?? "")) { image in
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