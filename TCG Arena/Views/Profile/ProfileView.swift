//
//  ProfileView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/5/25.
//

import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var reservationService: ReservationService
    @State private var selectedTab = 0
    @State private var showingEditProfile = false
    @State private var userStats: UserStats?
    @State private var myDecks: [Deck] = []
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // MARK: - Header
                VStack(spacing: 16) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 100, height: 100)
                        
                        if let user = authService.currentUser, let avatarUrl = user.profileImageUrl, let url = URL(string: avatarUrl) {
                            AsyncImage(url: url) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Text(String(user.displayName.prefix(1)).uppercased())
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.blue)
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                        } else {
                            Text(authService.currentUser?.displayName.prefix(1).uppercased() ?? "U")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.blue)
                        }
                        
                        // Edit Badge
                        Button(action: { showingEditProfile = true }) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    SwiftUI.Image(systemName: "pencil")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                )
                                .shadow(radius: 4)
                        }
                        .offset(x: 35, y: 35)
                    }
                    
                    // Info
                    VStack(spacing: 4) {
                        Text(authService.currentUser?.displayName ?? "TCG Player")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text(authService.currentUser?.favoriteGame?.rawValue.capitalized ?? "TCG Collector")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                .padding(.top, 20)
                
                // MARK: - Stats Grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    MinimalProfileStat(value: "\(userStats?.totalCards ?? 0)", label: "Carte")
                    MinimalProfileStat(value: "\(userStats?.totalDecks ?? 0)", label: "Mazzi")
                    MinimalProfileStat(value: "\(userStats?.totalTournaments ?? 0)", label: "Tornei")
                }
                .padding(.horizontal, 24)
                
                // MARK: - Content Tabs
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        ProfileTabButton(title: "Panoramica", isSelected: selectedTab == 0) { selectedTab = 0 }
                        ProfileTabButton(title: "Mazzi", isSelected: selectedTab == 1) { selectedTab = 1 }
                        ProfileTabButton(title: "Collezione", isSelected: selectedTab == 2) { selectedTab = 2 }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    
                    if selectedTab == 0 {
                        overviewContent
                    } else if selectedTab == 1 {
                        decksContent
                    } else {
                        collectionContent
                    }
                }
            }
            .padding(.bottom, 100)
        }
        .background(Color.white.ignoresSafeArea())
        .onAppear { loadData() }
        .sheet(isPresented: $showingEditProfile) {
            // Edit Profile Sheet (Placeholder or actual view if exists)
            Text("Modifica Profilo")
        }
    }
    
    // MARK: - Overview Content
    var overviewContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Bio - Removed: User model has no bio property
            
            // Location
            if let user = authService.currentUser, let city = user.location?.city {
                HStack {
                    SwiftUI.Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.red)
                    Text("\(city), \(user.location?.country ?? "")")
                        .font(.callout)
                }
                .padding(.horizontal, 24)
            }
            
            // Favorite TCGs (Read Only Display)
            if !authService.favoriteTCGTypes.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("GIOCHI PREFERITI")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .tracking(1)
                        .padding(.horizontal, 24)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(authService.favoriteTCGTypes, id: \.self) { tcg in
                                HStack {
                                    TCGIconView(tcgType: tcg, size: 16)
                                    Text(tcg.displayName)
                                        .font(.system(size: 14, weight: .bold))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(tcg.themeColor.opacity(0.1))
                                .foregroundColor(tcg.themeColor)
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
        }
    }
    
    // MARK: - Decks Content
    var decksContent: some View {
        VStack(spacing: 16) {
            if myDecks.isEmpty {
                Text("Nessun deck creato")
                    .foregroundColor(.secondary)
                    .padding(.top, 40)
            } else {
                ForEach(myDecks) { deck in
                    CompactDeckRow(deck: deck)
                }
                .padding(.horizontal, 24)
            }
        }
    }
    
    // MARK: - Collection Content
    var collectionContent: some View {
        VStack {
            Text("In Arrivo")
                .foregroundColor(.secondary)
                .padding(.top, 40)
        }
    }
    
    private func loadData() {
        guard let userId = authService.currentUserId else { return }
        Task {
            // Load Stats
            if let stats = try? await UserService.shared.getUserStats(userId: userId) {
                userStats = stats
            }
            // Load Decks
            DeckService.shared.loadUserDecks(userId: userId) { result in
                if case .success(let decks) = result {
                    myDecks = decks
                }
            }
        }
    }
}

// MARK: - Components

struct MinimalProfileStat: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct ProfileTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                Rectangle()
                    .fill(isSelected ? Color.blue : Color.clear)
                    .frame(height: 2)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct CompactDeckRow: View {
    let deck: Deck
    
    var body: some View {
        HStack(spacing: 12) {
            // Deck Art Placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(deck.tcgType.themeColor)
                .frame(width: 48, height: 48)
                .overlay(
                    TCGIconView(tcgType: deck.tcgType, size: 24)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(deck.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                Text("\(deck.cards.count) carte • \(deck.deckType.rawValue)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            SwiftUI.Image(systemName: "chevron.right")
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
