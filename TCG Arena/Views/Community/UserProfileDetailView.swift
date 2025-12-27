//
//  UserProfileDetailView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/10/25.
//

import SwiftUI
import UIKit

struct UserProfileDetailView: View {
    let userProfile: UserProfile
    @StateObject private var discoverService = DiscoverService()
    @StateObject private var deckService = DeckService()
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authService: AuthService
    
    @State private var selectedTab = 0
    @State private var userDecks: [Deck] = []
    @State private var aggregatedCards: [Deck.DeckCard] = [] // New state for cards
    @State private var isLoadingDecks = false
    @State private var userActivities: [UserActivity] = []
    @State private var isLoadingActivities = false
    
    // Chat State
    @StateObject private var chatService = ChatService()
    @State private var isChatActive = false
    @State private var activeConversation: ChatConversation?
    
    // Trade Lists State
    @StateObject private var tradeService = TradeService()
    @State private var wantList: [TradeListEntry] = []
    @State private var haveList: [TradeListEntry] = []
    
    // Computed props
    private var totalCardsCount: Int {
        userDecks.reduce(0) { $0 + $1.cards.reduce(0) { $0 + $1.quantity } }
    }
    
    private var hasOverviewContent: Bool {
        // Always show overview tab since we have shops and tournaments sections
        return true
    }
    
    var body: some View {
        NavigationView {
             ZStack(alignment: .top) {
                Color.white.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .center, spacing: 32) {
                        
                        // MARK: - Avatar & Basic Info
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(userProfile.preferredTCG?.themeColor.opacity(0.1) ?? Color.gray.opacity(0.1))
                                    .frame(width: 120, height: 120)
                                
                                Text(String(userProfile.displayName.prefix(1)).uppercased())
                                    .font(.system(size: 48, weight: .heavy, design: .rounded))
                                    .foregroundColor(userProfile.preferredTCG?.themeColor ?? .primary)
                                
                                // Verified Badge
                                if userProfile.isVerified {
                                    VStack {
                                        Spacer()
                                        HStack {
                                            Spacer()
                                            Circle()
                                                .fill(Color.blue)
                                                .frame(width: 32, height: 32)
                                                .overlay(SwiftUI.Image(systemName: "checkmark").font(.footnote).bold().foregroundColor(.white))
                                                .offset(x: 0, y: 0)
                                        }
                                    }
                                }
                            }
                            .frame(width: 120, height: 120)
                            
                            VStack(spacing: 4) {
                                Text(userProfile.displayName)
                                    .font(.system(size: 24, weight: .heavy))
                                    .foregroundColor(.primary)
                                
                                Text("@\(userProfile.username)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary)
                            }
                            
                            // Message Button - Minimalist style
                            Button(action: {
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                startChat()
                            }) {
                                HStack(spacing: 8) {
                                    SwiftUI.Image(systemName: "bubble.left")
                                        .font(.system(size: 14, weight: .medium))
                                    Text("Messaggio")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundColor(.primary)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(24)
                            }
                        }
                        .padding(.top, 20)
                        
                        // Navigation to Chat (Hidden Link)
                        NavigationLink(isActive: $isChatActive) {
                            if let conv = activeConversation {
                                ChatDetailView(conversation: conv, currentUserId: Int64(authService.currentUserId ?? 0))
                                    .environmentObject(authService)
                            }
                        } label: { EmptyView() }
                        
                        // MARK: - Stats Row
                        HStack(spacing: 40) {
                            MinimalStatItem(value: "\(userProfile.level)", label: "Livello")
                            MinimalStatItem(value: "\(userProfile.stats.tournamentsWon)", label: "Vittorie")
                            MinimalStatItem(value: "\(totalCardsCount)", label: "Carte")
                        }
                        
                        // MARK: - Modern Section Grid (Home-style)
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 12) {
                            ProfileSectionButton(
                                icon: "person.text.rectangle",
                                title: "Generale",
                                isSelected: selectedTab == 0
                            ) {
                                withAnimation(.spring(response: 0.3)) { selectedTab = 0 }
                            }
                            
                            ProfileSectionButton(
                                icon: "rectangle.stack",
                                title: "Decks",
                                isSelected: selectedTab == 1
                            ) {
                                withAnimation(.spring(response: 0.3)) { selectedTab = 1 }
                            }
                            
                            ProfileSectionButton(
                                icon: "square.stack.3d.up",
                                title: "Carte",
                                isSelected: selectedTab == 2
                            ) {
                                withAnimation(.spring(response: 0.3)) { selectedTab = 2 }
                            }
                            
                            ProfileSectionButton(
                                icon: "magnifyingglass",
                                title: "Cerco",
                                isSelected: selectedTab == 4
                            ) {
                                withAnimation(.spring(response: 0.3)) { selectedTab = 4 }
                            }
                            
                            ProfileSectionButton(
                                icon: "gift",
                                title: "Offro",
                                isSelected: selectedTab == 5
                            ) {
                                withAnimation(.spring(response: 0.3)) { selectedTab = 5 }
                            }
                            
                            ProfileSectionButton(
                                icon: "clock.arrow.circlepath",
                                title: "Attività",
                                isSelected: selectedTab == 3
                            ) {
                                withAnimation(.spring(response: 0.3)) { selectedTab = 3 }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // MARK: - Content
                        if selectedTab == 0 && hasOverviewContent {
                            overviewContent
                        } else if selectedTab == 1 {
                            decksContent
                        } else if selectedTab == 2 {
                             cardsContent
                        } else if selectedTab == 3 {
                            activityContent
                        } else if selectedTab == 4 {
                            tradeListContent(list: wantList, type: "Cerco")
                        } else if selectedTab == 5 {
                            tradeListContent(list: haveList, type: "Offro")
                        }
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        SwiftUI.Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onAppear {
                if !hasOverviewContent && selectedTab == 0 {
                    selectedTab = 1 // Default to Decks if Overview is hidden
                }
                loadUserData()
            }
        }
    }
    
    // MARK: - Subviews
    
    var overviewContent: some View {
        VStack(spacing: 24) {
            // Bio
            if let bio = userProfile.bio, !bio.isEmpty {
                Text(bio)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            // Trade Rating
            if let rating = userProfile.tradeRating {
                VStack(spacing: 8) {
                    HStack(spacing: 4) {
                        SwiftUI.Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.yellow)
                        Text("Rating Scambi")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(1)
                    }
                    
                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { star in
                            SwiftUI.Image(systemName: star <= Int(rating.rounded()) ? "star.fill" : "star")
                                .font(.system(size: 18))
                                .foregroundColor(.yellow)
                        }
                        Text(String(format: "%.1f", rating))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(.leading, 8)
                    }
                }
            }
            
            // Badges
            if !userProfile.badges.isEmpty {
                VStack(spacing: 12) {
                    Text("Badge")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(1)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(userProfile.badges, id: \.id) { badge in
                                MinimalBadgePill(badge: badge)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
            
            // Favorite Shops Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    SwiftUI.Image(systemName: "storefront")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Text("Negozi Preferiti")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(1)
                }
                .padding(.horizontal, 24)
                
                // Empty state - TODO: Load from API when available
                HStack(spacing: 12) {
                    SwiftUI.Image(systemName: "storefront.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("Nessun negozio preferito")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal, 24)
            }
            
            // Tournaments Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    SwiftUI.Image(systemName: "trophy")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Text("Tornei")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(1)
                }
                .padding(.horizontal, 24)
                
                if userProfile.stats.tournamentsPlayed > 0 {
                    // Show tournament stats
                    HStack(spacing: 16) {
                        VStack(spacing: 4) {
                            Text("\(userProfile.stats.tournamentsPlayed)")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.primary)
                            Text("Partecipati")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        
                        VStack(spacing: 4) {
                            Text("\(userProfile.stats.tournamentsWon)")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.orange)
                            Text("Vittorie")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        
                        VStack(spacing: 4) {
                            Text(String(format: "%.0f%%", userProfile.stats.winRate * 100))
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.green)
                            Text("Win Rate")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                } else {
                    // Empty state
                    HStack(spacing: 12) {
                        SwiftUI.Image(systemName: "trophy.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("Nessun torneo partecipato")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
                }
            }
            
            // Location - At the bottom
            if let location = userProfile.location, !location.city.isEmpty {
                HStack(spacing: 8) {
                    SwiftUI.Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                    Text("\(location.city), \(location.country)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
    }
    
    var decksContent: some View {
        VStack(spacing: 16) {
            if isLoadingDecks {
                ProgressView()
            } else if userDecks.isEmpty {
                Text("Nessun deck pubblico")
                    .foregroundColor(.secondary)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(userDecks) { deck in
                        MinimalDeckRow(deck: deck)
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
    
    var cardsContent: some View {
        VStack(spacing: 16) {
            if isLoadingDecks {
                ProgressView()
            } else if aggregatedCards.isEmpty {
                Text("Nessuna carta pubblica")
                    .foregroundColor(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60), spacing: 8)], spacing: 8) {
                    ForEach(aggregatedCards.prefix(50)) { card in // Limit to 50 for performance
                        MinimalCardItem(card: card)
                    }
                }
                .padding(.horizontal, 24)
                
                if aggregatedCards.count > 50 {
                   Text("+ altre \(aggregatedCards.count - 50)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
            }
        }
    }
    
    var activityContent: some View {
        VStack(spacing: 16) {
            if isLoadingActivities {
                ProgressView()
            } else if userActivities.isEmpty {
                Text("Nessuna attività recente")
                    .foregroundColor(.secondary)
            } else {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(userActivities.enumerated()), id: \.element.id) { index, activity in
                        TimelineActivityRow(activity: activity, isLast: index == userActivities.count - 1) {}
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
    
    func tradeListContent(list: [TradeListEntry], type: String) -> some View {
        VStack(spacing: 16) {
            if list.isEmpty {
                VStack(spacing: 12) {
                    SwiftUI.Image(systemName: type == "Cerco" ? "magnifyingglass" : "tag.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("Nessuna carta nella lista \(type)")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
                .padding(.top, 40)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 90, maximum: 110), spacing: 12)], spacing: 12) {
                    ForEach(list, id: \.id) { entry in
                        VStack(spacing: 4) {
                            if let imageUrl = entry.imageUrl, let url = URL(string: imageUrl) {
                                AsyncImage(url: url) { image in
                                    image.resizable().scaledToFit()
                                } placeholder: {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.2))
                                }
                                .frame(height: 130)
                                .cornerRadius(8)
                            } else {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 130)
                            }
                            Text(entry.cardName)
                                .font(.caption2)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
    
    // MARK: - Logic
    
    private func loadUserData() {
        guard let userId = Int64(userProfile.id) else { return }
        
        isLoadingDecks = true
        deckService.loadUserDecks(userId: userId, saveToCache: false) { result in
            DispatchQueue.main.async {
                self.isLoadingDecks = false
                if case .success(let decks) = result {
                    // Show all public decks
                    self.userDecks = decks
                    
                    // Aggregate cards from all decks by cardId
                    var cardsMap: [Int64: Deck.DeckCard] = [:]
                    
                    for deck in decks {
                        for card in deck.cards {
                            if let existing = cardsMap[card.cardId] {
                                // Create a new card with summed quantity
                                let updatedCard = Deck.DeckCard(
                                    id: existing.id,
                                    cardId: existing.cardId,
                                    quantity: existing.quantity + card.quantity,
                                    cardName: existing.cardName,
                                    cardImageUrl: existing.cardImageUrl,
                                    condition: existing.condition,
                                    rarity: existing.rarity,
                                    setName: existing.setName,
                                    isGraded: existing.isGraded,
                                    gradingCompany: existing.gradingCompany,
                                    grade: existing.grade,
                                    certificateNumber: existing.certificateNumber
                                )
                                cardsMap[card.cardId] = updatedCard
                            } else {
                                cardsMap[card.cardId] = card
                            }
                        }
                    }
                    
                    // Sort aggregated cards by name
                    self.aggregatedCards = cardsMap.values.sorted { $0.cardName < $1.cardName }
                }
            }
        }
        
        isLoadingActivities = true
        discoverService.getUserActivities(userId: userId, limit: 10) { result in
            isLoadingActivities = false
            if case .success(let activities) = result {
                self.userActivities = activities
            }
        }
        
        // Fetch trade lists
        Task {
            do {
                let want = try await tradeService.fetchUserList(userId: userId, type: .want)
                let have = try await tradeService.fetchUserList(userId: userId, type: .have)
                await MainActor.run {
                    self.wantList = want
                    self.haveList = have
                }
            } catch {
                print("❌ Error fetching trade lists: \(error)")
            }
        }
    }

    private func startChat() {
        guard let targetId = Int64(userProfile.id) else { return }
        chatService.startChat(targetUserId: targetId, type: .free) { conversation in
             DispatchQueue.main.async {
                 if let conv = conversation {
                     self.activeConversation = conv
                     self.isChatActive = true
                 }
             }
        }
    }
}

// MARK: - New Components

struct MinimalStatItem: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}

struct ProfileTabPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
             Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isSelected ? .primary : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSelected ? Color.white : Color.clear)
                .clipShape(Capsule())
                .shadow(color: isSelected ? Color.black.opacity(0.1) : .clear, radius: 2, x: 0, y: 1)
        }
    }
}

// MARK: - Modern Section Button (Home-style)
struct ProfileSectionButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.primary.opacity(0.1) : Color(.secondarySystemBackground))
                        .frame(width: 48, height: 48)
                    
                    SwiftUI.Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isSelected ? .primary : .secondary)
                }
                
                Text(title)
                    .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.white : Color.clear)
                    .shadow(color: isSelected ? Color.black.opacity(0.08) : .clear, radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.primary.opacity(0.1) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MinimalBadgePill: View {
    let badge: UserBadge
    
    var body: some View {
        HStack(spacing: 6) {
            SwiftUI.Image(systemName: badge.iconName)
                .font(.system(size: 10))
            Text(badge.name)
                .font(.system(size: 12, weight: .medium))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .foregroundColor(badge.color.color)
    }
}

struct MinimalCardItem: View {
    let card: Deck.DeckCard
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            AsyncImage(url: URL(string: card.cardImageUrl ?? "")) { image in
                image
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                Color.gray.opacity(0.1)
            }
            .frame(height: 84) // Aspect ratio roughly 2.5 : 3.5
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
            )
            
            if card.quantity > 1 {
                Text("x\(card.quantity)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(4)
                    .padding(2)
            }
        }
    }
}

struct MinimalDeckRow: View {
    let deck: Deck
    
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6)
                .fill(deck.tcgType.themeColor.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(deck.name.prefix(1)).uppercased())
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(deck.tcgType.themeColor)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(deck.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                Text("\(deck.cards.count) carte • \(deck.tcgType.displayName)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}
