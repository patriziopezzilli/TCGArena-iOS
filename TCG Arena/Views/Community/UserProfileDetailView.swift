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
    
    @State private var selectedTab = 0
    @State private var userDecks: [Deck] = []
    @State private var aggregatedCards: [Deck.DeckCard] = [] // New state for cards
    @State private var isLoadingDecks = false
    @State private var userActivities: [UserActivity] = []
    @State private var isLoadingActivities = false
    
    // Computed props
    private var totalCardsCount: Int {
        userDecks.reduce(0) { $0 + $1.cards.reduce(0) { $0 + $1.quantity } }
    }
    
    private var hasOverviewContent: Bool {
        let hasBio = !(userProfile.bio?.isEmpty ?? true)
        let hasLocation = userProfile.location != nil
        let hasBadges = !userProfile.badges.isEmpty
        return hasBio || hasLocation || hasBadges
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
                            
                            // Coming Soon Button
                            Button(action: {
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                // Optional: Show toast here if ToastManager is available
                            }) {
                                HStack(spacing: 6) {
                                    SwiftUI.Image(systemName: "clock.fill")
                                    .font(.system(size: 12))
                                    Text("Coming Soon")
                                        .font(.system(size: 12, weight: .bold))
                                }
                                .foregroundColor(.white.opacity(0.8))
                                .frame(width: 140, height: 36)
                                .background(Color.gray.opacity(0.5))
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                            }
                            .disabled(true)
                        }
                        .padding(.top, 20)
                        
                        // MARK: - Stats Row
                        HStack(spacing: 40) {
                            MinimalStatItem(value: "\(userProfile.level)", label: "Livello")
                            MinimalStatItem(value: "\(userProfile.stats.tournamentsWon)", label: "Vittorie")
                            MinimalStatItem(value: "\(totalCardsCount)", label: "Carte")
                        }
                        
                        // MARK: - Tabs
                        HStack(spacing: 0) {
                            if hasOverviewContent {
                                ProfileTabPill(title: "Overview", isSelected: selectedTab == 0) { withAnimation { selectedTab = 0 } }
                            }
                            ProfileTabPill(title: "Decks", isSelected: selectedTab == 1) { withAnimation { selectedTab = 1 } }
                            ProfileTabPill(title: "Carte", isSelected: selectedTab == 2) { withAnimation { selectedTab = 2 } }
                            ProfileTabPill(title: "Attività", isSelected: selectedTab == 3) { withAnimation { selectedTab = 3 } }
                        }
                        .padding(4)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Capsule())
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
            
            // Location
            if let location = userProfile.location, !location.city.isEmpty {
                HStack {
                    SwiftUI.Image(systemName: "mappin.and.ellipse")
                    Text("\(location.city), \(location.country)")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
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
    
    // MARK: - Logic
    
    private func loadUserData() {
        guard let userId = Int64(userProfile.id) else { return }
        
        isLoadingDecks = true
        deckService.loadUserDecks(userId: userId, saveToCache: false) { result in
             // Assumes DeckService returns on main or we leverage SwiftUI state safety update in next runloop naturally if not strict
             isLoadingDecks = false
             if case .success(let decks) = result {
                 let validDecks = decks.filter { $0.deckType == .lista }
                 self.userDecks = validDecks
                 // Aggregate cards
                 self.aggregatedCards = validDecks.flatMap { $0.cards }
             }
        }
        
        isLoadingActivities = true
        discoverService.getUserActivities(userId: userId, limit: 10) { result in
            isLoadingActivities = false
            if case .success(let activities) = result {
                self.userActivities = activities
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