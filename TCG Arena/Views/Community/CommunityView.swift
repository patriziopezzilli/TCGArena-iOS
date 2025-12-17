//
//  CommunityView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/5/25.
//

import SwiftUI
import CoreLocation

struct CommunityView: View {
    @StateObject private var discoverService = DiscoverService()
    @EnvironmentObject var authService: AuthService
    
    @State private var selectedSection = 0
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
    
    private func filteredEntries(_ entries: [LeaderboardEntry]) -> [LeaderboardEntry] {
        guard locationFilter == .nearby,
              let currentUserId = authService.currentUserId else {
            return entries
        }
        
        // 1. Try to get location from logged in user
        // 2. Fallback to finding user in the leaderboard entries
        let userLocation: UserLocation?
        
        if let authLocation = authService.currentUser?.location {
            userLocation = authLocation
        } else {
            userLocation = entries.first { $0.userProfile.id == String(currentUserId) }?.userProfile.location
        }
        
        guard let location = userLocation else { return entries }
        
        // Use coordinates if available
        if let lat = location.latitude, let lon = location.longitude {
            let userLoc = CLLocation(latitude: lat, longitude: lon)
            
            return entries.filter { entry in
                guard let entryLat = entry.userProfile.location?.latitude,
                      let entryLon = entry.userProfile.location?.longitude else {
                    return false
                }
                
                let entryLoc = CLLocation(latitude: entryLat, longitude: entryLon)
                // Filter within 50km
                return userLoc.distance(from: entryLoc) <= 50000
            }
        }
        
        // Fallback to city
        guard let city = location.city as String?, !city.isEmpty else {
            return entries
        }
        
        return entries.filter { entry in
            entry.userProfile.location?.city.lowercased() == city.lowercased()
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Content
                    ScrollView {
                        LazyVStack(spacing: 24) {
                            // Segmented Control
                            segmentedControl
                            
                            // Content based on selection
                            if selectedSection == 0 {
                                leaderboardContent
                            } else if selectedSection == 1 {
                                exploreContent
                            } else {
                                discoverContent
                            }
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
                    .refreshable {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        discoverService.refreshData()
                    }
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .sheet(item: $showingUserProfile) { user in
                UserProfileDetailView(userProfile: user)
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Community")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Scopri e connettiti")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Location Filter Pill
                Menu {
                    ForEach(LocationFilter.allCases, id: \.rawValue) { filter in
                        Button(action: {
                            withAnimation { locationFilter = filter }
                        }) {
                            Label(filter.rawValue, systemImage: filter.icon)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        SwiftUI.Image(systemName: locationFilter.icon)
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                        
                        Text(locationFilter.rawValue)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                        
                        SwiftUI.Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
        }
        .background(
            Rectangle()
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Segmented Control
    
    private var segmentedControl: some View {
        HStack(spacing: 0) {
            CommunityTabButton(
                icon: "trophy.fill",
                label: "Classifiche",
                isSelected: selectedSection == 0
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedSection = 0
                }
            }
            
            CommunityTabButton(
                icon: "sparkles",
                label: "Esplora",
                isSelected: selectedSection == 1
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedSection = 1
                }
            }
            
            CommunityTabButton(
                icon: "person.2.fill",
                label: "Giocatori",
                isSelected: selectedSection == 2
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedSection = 2
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Explore Content (Activity Feed)
    
    private var exploreContent: some View {
        let activities: [UserActivity] = discoverService.recentActivities
        
        return VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cosa succede")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    Text("Attività recenti della community")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            
            if activities.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.purple.opacity(0.1))
                            .frame(width: 80, height: 80)
                        SwiftUI.Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 32))
                            .foregroundColor(.purple)
                    }
                    
                    Text("Nessuna attività recente")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Le attività dei giocatori appariranno qui")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 60)
                .frame(maxWidth: .infinity)
            } else {
                // Activity Feed
                activityFeedList(activities: activities)
            }
        }
    }
    
    @ViewBuilder
    private func activityFeedList(activities: [UserActivity]) -> some View {
        LazyVStack(spacing: 0) {
            ForEach(activities, id: \.id) { activity in
                activityRow(activity: activity)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private func activityRow(activity: UserActivity) -> some View {
        ActivityFeedCard(activity: activity) {
            handleActivityTap(activity: activity)
        }
    }
    
    private func handleActivityTap(activity: UserActivity) {
        guard let userId = activity.userId else { return }
        let profile = UserProfile(
            id: String(userId),
            username: activity.username ?? "user",
            displayName: activity.displayName ?? "User",
            avatarURL: nil,
            bio: nil,
            joinDate: Date(),
            lastActiveDate: Date(),
            isVerified: false,
            level: 1,
            experience: 0,
            stats: DiscoverUserStats(
                totalCards: 0,
                totalDecks: 0,
                tournamentsWon: 0,
                tournamentsPlayed: 0,
                tradesToday: 0,
                totalTrades: 0,
                communityPoints: 0,
                achievementsUnlocked: 0
            ),
            badges: [],
            favoriteCard: nil,
            preferredTCG: nil,
            location: nil,
            followersCount: 0,
            followingCount: 0,
            isFollowedByCurrentUser: false
        )
        showingUserProfile = profile
    }
    
    // MARK: - Leaderboard Content
    
    private var leaderboardContent: some View {
        VStack(spacing: 20) {
            // Leaderboard Type Cards
            ForEach(LeaderboardType.allCases) { type in
                LeaderboardCard(
                    type: type,
                    entries: filteredEntries(discoverService.leaderboards[type] ?? []),
                    onUserTap: { user in showingUserProfile = user }
                )
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Discover Content
    
    private var discoverContent: some View {
        VStack(spacing: 24) {
            // Top Players Section
            if !discoverService.featuredUsers.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    CommunitySectionHeader(title: "Top Giocatori", icon: "star.fill", color: .yellow)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(discoverService.featuredUsers) { userProfile in
                                FeaturedPlayerCard(user: userProfile.toUserProfile()) {
                                    showingUserProfile = userProfile.toUserProfile()
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            
            // New Members Section
            if !discoverService.newUsers.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    CommunitySectionHeader(title: "Nuovi Membri", icon: "person.badge.plus", color: .green)
                    
                    let nonGuestUsers = discoverService.newUsers.filter { !$0.username.lowercased().contains("guest") }
                    
                    VStack(spacing: 0) {
                        ForEach(Array(nonGuestUsers.prefix(5).enumerated()), id: \.element.id) { index, user in
                            NewMemberRow(user: user.toUserProfile()) {
                                showingUserProfile = user.toUserProfile()
                            }
                            
                            if index < min(4, nonGuestUsers.count - 1) {
                                Divider()
                                    .padding(.leading, 70)
                            }
                        }
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                }
            }
        }
    }
}

// MARK: - Components

struct CommunityTabButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                SwiftUI.Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue : Color.clear)
            )
        }
    }
}

struct CommunitySectionHeader: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)
                SwiftUI.Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

struct LeaderboardCard: View {
    let type: LeaderboardType
    let entries: [LeaderboardEntry]
    let onUserTap: (UserProfile) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(type.color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    SwiftUI.Image(systemName: type.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(type.color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(type.displayName)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.primary)
                    Text("Top 5 giocatori")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(16)
            
            Divider()
            
            // Entries
            if entries.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        SwiftUI.Image(systemName: "chart.bar")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("Nessun dato")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 24)
                    Spacer()
                }
            } else {
                ForEach(Array(entries.prefix(5).enumerated()), id: \.element.id) { index, entry in
                    Button(action: { onUserTap(entry.userProfile) }) {
                        HStack(spacing: 14) {
                            // Rank
                            RankBadge(rank: index + 1)
                            
                            // Avatar
                            Circle()
                                .fill(Color(.systemGray5))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Text(String(entry.userProfile.displayName.prefix(1)).uppercased())
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.primary)
                                )
                            
                            // Name
                            Text(entry.userProfile.displayName)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            // Score
                            Text("\(entry.score)")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(type.color)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if index < min(4, entries.count - 1) {
                        Divider()
                            .padding(.leading, 70)
                    }
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

struct RankBadge: View {
    let rank: Int
    
    private var color: Color {
        switch rank {
        case 1: return .yellow
        case 2: return Color(.systemGray3)
        case 3: return .orange
        default: return .secondary
        }
    }
    
    var body: some View {
        ZStack {
            if rank <= 3 {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 28, height: 28)
            }
            Text("\(rank)")
                .font(.system(size: rank <= 3 ? 14 : 13, weight: .bold))
                .foregroundColor(rank <= 3 ? color : .secondary)
        }
        .frame(width: 28)
    }
}

struct FeaturedPlayerCard: View {
    let user: UserProfile
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Avatar with verification badge
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 56, height: 56)
                        .overlay(
                            Text(String(user.displayName.prefix(2)).uppercased())
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.primary)
                        )
                    
                    if user.isVerified {
                        Circle()
                            .fill(Color(.systemBackground))
                            .frame(width: 20, height: 20)
                            .overlay(
                                SwiftUI.Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.blue)
                            )
                            .offset(x: 2, y: 2)
                    }
                }
                
                VStack(spacing: 4) {
                    Text(user.displayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text("Lv. \(user.level)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                // Stats
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        SwiftUI.Image(systemName: "trophy.fill")
                            .font(.system(size: 10))
                        Text("\(user.stats.tournamentsWon)")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.orange)
                    
                    HStack(spacing: 4) {
                        SwiftUI.Image(systemName: "rectangle.stack.fill")
                            .font(.system(size: 10))
                        Text("\(user.stats.totalCards)")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.blue)
                }
            }
            .padding(14)
            .frame(width: 130)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NewMemberRow: View {
    let user: UserProfile
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Avatar with badge
                ZStack(alignment: .topTrailing) {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Text(String(user.displayName.prefix(2)).uppercased())
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)
                        )
                    
                    Circle()
                        .fill(Color.green)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Text("N")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .offset(x: 2, y: -2)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(user.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("@\(user.username)")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                SwiftUI.Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ActivityFeedCard: View {
    let activity: UserActivity
    let onTap: () -> Void
    
    private var activityIcon: String {
        switch activity.activityType.lowercased() {
        case "tournament_win", "tournament_participation":
            return "trophy.fill"
        case "deck_created", "deck_updated":
            return "rectangle.stack.fill"
        case "card_added", "card_collected":
            return "plus.rectangle.fill"
        case "level_up":
            return "arrow.up.circle.fill"
        case "badge_earned":
            return "star.fill"
        case "profile_updated":
            return "person.fill"
        case "reward_redeemed":
            return "gift.fill"
        default:
            return "sparkles"
        }
    }
    
    private var activityColor: Color {
        switch activity.activityType.lowercased() {
        case "tournament_win":
            return .yellow
        case "tournament_participation":
            return .orange
        case "deck_created", "deck_updated":
            return .purple
        case "card_added", "card_collected":
            return .blue
        case "level_up":
            return .green
        case "badge_earned":
            return .yellow
        case "reward_redeemed":
            return .pink
        default:
            return .gray
        }
    }
    
    private var timeAgo: String {
        // Parse ISO timestamp
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: activity.timestamp) else {
            // Try without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            guard let date2 = formatter.date(from: activity.timestamp) else {
                return ""
            }
            return formatTimeAgo(from: date2)
        }
        return formatTimeAgo(from: date)
    }
    
    private func formatTimeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "ora"
        } else if interval < 3600 {
            let mins = Int(interval / 60)
            return "\(mins)m fa"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h fa"
        } else if interval < 604800 {
            let days = Int(interval / 86400)
            return "\(days)g fa"
        } else {
            let weeks = Int(interval / 604800)
            return "\(weeks)sett fa"
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Activity Icon Circle
                ZStack {
                    Circle()
                        .fill(activityColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    SwiftUI.Image(systemName: activityIcon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(activityColor)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    // User info
                    HStack(spacing: 6) {
                        Text(activity.displayName ?? activity.username ?? "Utente")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.primary)
                        
                        if let username = activity.username {
                            Text("@\(username)")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Activity description
                    Text(activity.description)
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Timestamp
                    Text(timeAgo)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(16)
            .background(
                Rectangle()
                    .fill(Color(.systemBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
        
        Divider()
            .padding(.leading, 72)
    }
}

#Preview {
    CommunityView()
        .environmentObject(AuthService())
}
