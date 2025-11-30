//
//  DiscoverView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/5/25.
//

import SwiftUI

struct DiscoverView: View {
    @StateObject private var discoverService = DiscoverService()
    @StateObject private var expansionService = ExpansionService()
    @StateObject private var cardService = CardService()
    @State private var selectedLeaderboardType: LeaderboardType = .tournaments
    @State private var showingUserProfile: UserProfile?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(spacing: 16) {
                    // Featured Users Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Top Players")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                if discoverService.featuredUsers.isEmpty {
                                    EmptyStateCard(message: "Nessun giocatore top disponibile")
                                        .frame(width: 140, height: 180)
                                } else {
                                    ForEach(discoverService.featuredUsers) { userProfile in
                                        FeaturedUserCard(user: userProfile.toUserProfile()) {
                                            showingUserProfile = userProfile.toUserProfile()
                                        }
                                        .frame(width: 140, height: 180)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                        }
                        .frame(height: 196)
                    }
                    
                    // Leaderboards Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Leaderboards")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        // Leaderboard Type Selector
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(LeaderboardType.allCases) { type in
                                    LeaderboardTypeButton(
                                        type: type,
                                        isSelected: selectedLeaderboardType == type
                                    ) {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedLeaderboardType = type
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Leaderboard List
                        VStack(spacing: 8) {
                            if discoverService.leaderboards[selectedLeaderboardType]?.isEmpty ?? true {
                                EmptyStateRow(message: "Nessuna classifica disponibile")
                            } else {
                                ForEach(Array((discoverService.leaderboards[selectedLeaderboardType] ?? []).prefix(5).enumerated()), id: \.element.id) { index, entry in
                                    DiscoverLeaderboardRow(entry: entry, position: index + 1) {
                                        showingUserProfile = entry.userProfile
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Recent Activity
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recent Activity")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        VStack(spacing: 12) {
                            if discoverService.recentActivities.isEmpty {
                                EmptyStateRow(message: "Nessuna attività recente")
                            } else {
                                ForEach(Array(discoverService.recentActivities.prefix(4))) { activity in
                                    ActivityCard(activity: activity) {
                                        showingUserProfile = activity.userProfile
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // New Users Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("New Members")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                if discoverService.newUsers.isEmpty {
                                    EmptyStateCard(message: "Nessun nuovo membro")
                                        .frame(width: 100)
                                } else {
                                    ForEach(discoverService.newUsers.prefix(5), id: \.id) { user in
                                        NewUserCard(user: user.toUserProfile()) {
                                            showingUserProfile = user.toUserProfile()
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    // New Cards Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("New Cards")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                if expansionService.expansions.isEmpty {
                                    EmptyStateCard(message: "Nessuna espansione disponibile")
                                        .frame(width: 140)
                                } else {
                                    ForEach(expansionService.expansions.prefix(5)) { expansion in
                                        ExpansionCard(expansion: expansion, action: {
                                            // For now, just show expansion, could navigate to expansion detail
                                        })
                                        .frame(width: 180, height: 220)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical, 8)
                        }
            }
        }
            }
        .navigationBarHidden(true)
        .refreshable {
            // Refresh data
        }
        .sheet(item: $showingUserProfile) { (user: UserProfile) in
            UserProfileDetailView(userProfile: user)
        }
        }
    }
    
struct HeroHeaderView: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                SwiftUI.Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Featured User Card
struct FeaturedUserCard: View {
    let user: UserProfile
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Avatar and Verification
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [user.preferredTCG?.themeColor ?? .blue, user.preferredTCG?.themeColor.opacity(0.7) ?? .blue.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 60, height: 60)
                    
                    Text(String(user.displayName.prefix(2)).uppercased())
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    if user.isVerified {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                SwiftUI.Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.blue)
                                    .background(Circle().fill(.white))
                            }
                        }
                        .frame(width: 60, height: 60)
                    }
                }
                
                VStack(spacing: 4) {
                    Text(user.displayName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text("Level \(user.level)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                // Stats
                VStack(spacing: 6) {
                    HStack(spacing: 4) {
                        SwiftUI.Image(systemName: "trophy.fill")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.yellow)
                        
                        Text("\(user.stats.tournamentsWon)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    
                    HStack(spacing: 4) {
                        SwiftUI.Image(systemName: "square.stack.3d.up.fill")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.blue)
                        
                        Text("\(user.stats.totalCards)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding(16)
            .frame(width: 140)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Leaderboard Type Button
struct LeaderboardTypeButton: View {
    let type: LeaderboardType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                SwiftUI.Image(systemName: type.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isSelected ? .white : type.color)
                
                Text(type.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? type.color : Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DiscoverView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoverView()
    }
}