//
//  DiscoverView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/5/25.
//

import SwiftUI

struct DiscoverView: View {
    @StateObject private var discoverService = DiscoverService()

    @State private var selectedLeaderboardType: LeaderboardType = .tournaments
    @State private var showingUserProfile: UserProfile?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // 1. Featured Users (Top Players)
                VStack(alignment: .leading, spacing: 16) {
                    DiscoverSectionHeader(title: "Top Players", subtitle: "The best of the best")
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            if discoverService.featuredUsers.isEmpty {
                                EmptyStateCard(message: "No top players yet")
                                    .frame(width: 160, height: 220)
                            } else {
                                ForEach(discoverService.featuredUsers) { userProfile in
                                    PremiumUserCard(user: userProfile.toUserProfile()) {
                                        showingUserProfile = userProfile.toUserProfile()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                // 2. Leaderboards
                VStack(alignment: .leading, spacing: 16) {
                    DiscoverSectionHeader(title: "Leaderboards", subtitle: "See who's leading the charts")
                    
                    // Type Selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(LeaderboardType.allCases) { type in
                                LeaderboardTypePill(
                                    type: type,
                                    isSelected: selectedLeaderboardType == type
                                ) {
                                    withAnimation {
                                        selectedLeaderboardType = type
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // List
                    VStack(spacing: 12) {
                        if let entries = discoverService.leaderboards[selectedLeaderboardType], !entries.isEmpty {
                            ForEach(Array(entries.prefix(5).enumerated()), id: \.element.id) { index, entry in
                                LeaderboardRowItem(entry: entry, rank: index + 1) {
                                    showingUserProfile = entry.userProfile
                                }
                            }
                        } else {
                            EmptyStateRow(message: "No leaderboard data available")
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // 3. New Members
                VStack(alignment: .leading, spacing: 16) {
                    DiscoverSectionHeader(title: "New Members", subtitle: "Welcome our latest players")
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            if discoverService.newUsers.isEmpty {
                                EmptyStateCard(message: "No new members")
                                    .frame(width: 140, height: 180)
                            } else {
                                ForEach(discoverService.newUsers.prefix(5), id: \.id) { user in
                                    NewMemberCard(user: user.toUserProfile()) {
                                        showingUserProfile = user.toUserProfile()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                


            }
            .padding(.top, 10)
        }
        .background(Color(.systemGroupedBackground))
        .sheet(item: $showingUserProfile) { user in
            UserProfileDetailView(userProfile: user)
        }
    }
}

// MARK: - Components

// Removed duplicate SectionHeader and ExpansionCard structs.
// They are already defined in other files or should be imported/renamed if specific to this view.
// Assuming we use the shared components or rename them to avoid conflicts.

struct DiscoverSectionHeader: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            Text(subtitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
    }
}

struct PremiumUserCard: View {
    let user: UserProfile
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [user.preferredTCG?.themeColor ?? .blue, (user.preferredTCG?.themeColor ?? .blue).opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                    
                    Text(String(user.displayName.prefix(2)).uppercased())
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    if user.isVerified {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                SwiftUI.Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .background(Circle().fill(Color.blue).padding(2))
                            }
                        }
                    }
                }
                .frame(width: 70, height: 70)
                
                // Info
                VStack(spacing: 4) {
                    Text(user.displayName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text("Level \(user.level)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                // Stats
                HStack(spacing: 12) {
                    StatBadge(icon: "trophy.fill", value: "\(user.stats.tournamentsWon)", color: .yellow)
                    StatBadge(icon: "rectangle.stack.fill", value: "\(user.stats.totalCards)", color: .blue)
                }
            }
            .padding(16)
            .frame(width: 160, height: 220)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StatBadge: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            SwiftUI.Image(systemName: icon)
                .font(.system(size: 10))
            Text(value)
                .font(.system(size: 12, weight: .bold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct LeaderboardTypePill: View {
    let type: LeaderboardType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                SwiftUI.Image(systemName: type.icon)
                    .font(.system(size: 12))
                Text(type.displayName)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? type.color : Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
        }
    }
}

struct LeaderboardRowItem: View {
    let entry: LeaderboardEntry
    let rank: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Rank
                Text("\(rank)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(rank <= 3 ? .primary : .secondary)
                    .frame(width: 30)
                
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Text(String(entry.userProfile.displayName.prefix(1)).uppercased())
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.secondary)
                }
                
                // Name
                Text(entry.userProfile.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Score
                Text("\(entry.score)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.blue)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NewMemberCard: View {
    let user: UserProfile
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 50, height: 50)
                    Text(String(user.displayName.prefix(1)).uppercased())
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                Text(user.displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            .padding(12)
            .frame(width: 100, height: 120)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DiscoverView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoverView()
    }
}