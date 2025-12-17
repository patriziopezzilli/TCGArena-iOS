//
//  DiscoverView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/5/25.
//

import SwiftUI

struct DiscoverView: View {
    @StateObject private var discoverService = DiscoverService()
    @EnvironmentObject var authService: AuthService

    @State private var selectedLeaderboardType: LeaderboardType = .tournaments
    @State private var showingUserProfile: UserProfile?
    @State private var locationFilter: LocationFilter = .global
    
    enum LocationFilter: String, CaseIterable {
        case global = "Globale"
        case nearby = "Vicino a me"
        
        var icon: String {
            switch self {
            case .global: return "globe"
            case .nearby: return "location.fill"
            }
        }
    }
    
    // Filter leaderboard entries by location
    private func filteredEntries(_ entries: [LeaderboardEntry]) -> [LeaderboardEntry] {
        guard locationFilter == .nearby,
              let currentUserId = authService.currentUserId else {
            return entries
        }
        
        let currentUserCity = entries
            .first { $0.userProfile.id == String(currentUserId) }?
            .userProfile.location?.city
        
        guard let city = currentUserCity, !city.isEmpty else {
            return entries
        }
        
        return entries.filter { entry in
            entry.userProfile.location?.city.lowercased() == city.lowercased()
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 32) {
                // Top Players Section
                topPlayersSection
                
                // Leaderboard Section
                leaderboardSection
                
                // New Members Section
                newMembersSection
            }
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .refreshable {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            await withCheckedContinuation { continuation in
                discoverService.refreshData()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    continuation.resume()
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .sheet(item: $showingUserProfile) { user in
            UserProfileDetailView(userProfile: user)
        }
    }
    
    // MARK: - Top Players Section
    
    private var topPlayersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Top Giocatori", icon: "star.fill")
            
            if discoverService.featuredUsers.isEmpty {
                emptyState(icon: "person.3", message: "Nessun top player ancora")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(discoverService.featuredUsers) { userProfile in
                            TopPlayerCard(user: userProfile.toUserProfile()) {
                                showingUserProfile = userProfile.toUserProfile()
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
    
    // MARK: - Leaderboard Section
    
    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Classifica", icon: "trophy.fill")
            
            // Filters
            VStack(spacing: 12) {
                // Location filter
                HStack(spacing: 8) {
                    ForEach(LocationFilter.allCases, id: \.rawValue) { filter in
                        LocationFilterChip(
                            title: filter.rawValue,
                            icon: filter.icon,
                            isSelected: locationFilter == filter
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                locationFilter = filter
                            }
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                
                // Type filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(LeaderboardType.allCases) { type in
                            TypeChip(
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
            }
            
            // Leaderboard List
            VStack(spacing: 0) {
                if let entries = discoverService.leaderboards[selectedLeaderboardType] {
                    let filtered = filteredEntries(entries)
                    if filtered.isEmpty {
                        emptyState(
                            icon: locationFilter == .nearby ? "location.slash" : "chart.bar",
                            message: locationFilter == .nearby ? "Nessun giocatore nella tua città" : "Nessun dato disponibile"
                        )
                    } else {
                        ForEach(Array(filtered.prefix(10).enumerated()), id: \.element.id) { index, entry in
                            RankingRow(entry: entry, rank: index + 1) {
                                showingUserProfile = entry.userProfile
                            }
                            
                            if index < min(9, filtered.count - 1) {
                                Divider()
                                    .padding(.leading, 70)
                            }
                        }
                    }
                } else {
                    emptyState(icon: "chart.bar", message: "Nessun dato disponibile")
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - New Members Section
    
    private var newMembersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Nuovi Membri", icon: "person.badge.plus")
            
            if discoverService.newUsers.isEmpty {
                emptyState(icon: "person.badge.plus", message: "Nessun nuovo membro")
            } else {
                let nonGuestUsers = discoverService.newUsers.filter { !$0.username.lowercased().contains("guest") }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(nonGuestUsers.prefix(8), id: \.id) { user in
                            NewMemberChip(user: user.toUserProfile()) {
                                showingUserProfile = user.toUserProfile()
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            SwiftUI.Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 20)
    }
    
    private func emptyState(icon: String, message: String) -> some View {
        HStack {
            Spacer()
            VStack(spacing: 12) {
                SwiftUI.Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(.secondary.opacity(0.5))
                Text(message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 32)
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Components

struct TopPlayerCard: View {
    let user: UserProfile
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Avatar
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 64, height: 64)
                        .overlay(
                            Text(String(user.displayName.prefix(2)).uppercased())
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.primary)
                        )
                    
                    if user.isVerified {
                        Circle()
                            .fill(Color(.systemBackground))
                            .frame(width: 22, height: 22)
                            .overlay(
                                SwiftUI.Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.blue)
                            )
                            .offset(x: 2, y: 2)
                    }
                }
                
                // Name
                Text(user.displayName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                // Level
                Text("Lv. \(user.level)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                
                // Stats row
                HStack(spacing: 12) {
                    Label("\(user.stats.tournamentsWon)", systemImage: "trophy.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.orange)
                    
                    Label("\(user.stats.totalCards)", systemImage: "rectangle.stack.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.blue)
                }
            }
            .padding(16)
            .frame(width: 140)
            .background(Color(.systemBackground))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct LocationFilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                SwiftUI.Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : .secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.primary : Color(.systemGray6))
            .cornerRadius(20)
        }
    }
}

struct TypeChip: View {
    let type: LeaderboardType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                SwiftUI.Image(systemName: type.icon)
                    .font(.system(size: 11, weight: .medium))
                Text(type.displayName)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? type.color : Color(.systemGray6))
            .cornerRadius(20)
        }
    }
}

struct RankingRow: View {
    let entry: LeaderboardEntry
    let rank: Int
    let onTap: () -> Void
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return Color(.systemGray3)
        case 3: return .orange
        default: return .clear
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Rank badge
                ZStack {
                    if rank <= 3 {
                        Circle()
                            .fill(rankColor.opacity(0.2))
                            .frame(width: 32, height: 32)
                    }
                    Text("\(rank)")
                        .font(.system(size: rank <= 3 ? 16 : 14, weight: .bold))
                        .foregroundColor(rank <= 3 ? rankColor : .secondary)
                }
                .frame(width: 32)
                
                // Avatar
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(entry.userProfile.displayName.prefix(1)).uppercased())
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                    )
                
                // Name
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.userProfile.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    if let city = entry.userProfile.location?.city, !city.isEmpty {
                        Text(city)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Score
                Text("\(entry.score)")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NewMemberChip: View {
    let user: UserProfile
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(String(user.displayName.prefix(1)).uppercased())
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                    )
                
                Text(user.displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
            .cornerRadius(24)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Keep for backward compatibility

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
        TopPlayerCard(user: user, onTap: onTap)
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
        TypeChip(type: type, isSelected: isSelected, onTap: onTap)
    }
}

struct LeaderboardRowItem: View {
    let entry: LeaderboardEntry
    let rank: Int
    let onTap: () -> Void
    
    var body: some View {
        RankingRow(entry: entry, rank: rank, onTap: onTap)
    }
}

struct NewMemberCard: View {
    let user: UserProfile
    let onTap: () -> Void
    
    var body: some View {
        NewMemberChip(user: user, onTap: onTap)
    }
}

// EmptyStateCard and EmptyStateRow are already defined in DiscoverComponents.swift

#Preview {
    DiscoverView()
}
