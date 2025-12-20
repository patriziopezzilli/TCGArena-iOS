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
        
        // Location filtering logic (kept from original)
        let userLocation: UserLocation?
        
        if let authLocation = authService.currentUser?.location {
            userLocation = authLocation
        } else {
            userLocation = entries.first { $0.userProfile.id == String(currentUserId) }?.userProfile.location
        }
        
        guard let location = userLocation else { return entries }
        
        if let lat = location.latitude, let lon = location.longitude {
            let userLoc = CLLocation(latitude: lat, longitude: lon)
            return entries.filter { entry in
                guard let entryLat = entry.userProfile.location?.latitude,
                      let entryLon = entry.userProfile.location?.longitude else { return false }
                let entryLoc = CLLocation(latitude: entryLat, longitude: entryLon)
                return userLoc.distance(from: entryLoc) <= 50000
            }
        }
        
        guard let city = location.city as String?, !city.isEmpty else { return entries }
        return entries.filter { entry in entry.userProfile.location?.city.lowercased() == city.lowercased() }
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        
                        // MARK: - Editorial Header
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("ARENA SOCIAL")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                    .tracking(2)
                                Spacer()
                                
                                // Location Filter Button
                                Menu {
                                    ForEach(LocationFilter.allCases, id: \.rawValue) { filter in
                                        Button(action: { withAnimation { locationFilter = filter } }) {
                                            Label(filter.rawValue, systemImage: filter.icon)
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        SwiftUI.Image(systemName: locationFilter.icon)
                                            .font(.system(size: 12))
                                        Text(locationFilter.rawValue)
                                            .font(.system(size: 12, weight: .bold))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color(.secondarySystemBackground))
                                    .foregroundColor(.primary)
                                    .clipShape(Capsule())
                                }
                                
                                // Explicit Refresh Button
                                Button(action: {
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.impactOccurred()
                                    discoverService.loadData {}
                                }) {
                                    SwiftUI.Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.primary)
                                        .padding(8)
                                        .background(Color(.secondarySystemBackground))
                                        .clipShape(Circle())
                                }
                            }
                            
                            Text("Hall of Fame.")
                                .font(.system(size: 34, weight: .heavy, design: .default))
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        
                        // MARK: - Tab Selector
                        HStack(spacing: 0) {
                            CommunityTabPill(title: "Classifiche", isSelected: selectedSection == 0) { withAnimation { selectedSection = 0 } }
                            CommunityTabPill(title: "Live Feed", isSelected: selectedSection == 1) { withAnimation { selectedSection = 1 } }
                            CommunityTabPill(title: "Giocatori", isSelected: selectedSection == 2) { withAnimation { selectedSection = 2 } }
                        }
                        .padding(4)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(Capsule())
                        .padding(.horizontal, 24)
                        
                        // MARK: - Content
                        if selectedSection == 0 {
                            leaderboardContent
                                .transition(.opacity)
                        } else if selectedSection == 1 {
                            exploreContent
                                .transition(.opacity)
                        } else {
                            discoverContent
                                .transition(.opacity)
                        }
                        
                        Spacer(minLength: 100)
                    }
                }
                .refreshable {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    await withCheckedContinuation { continuation in
                        discoverService.loadData {
                            continuation.resume()
                        }
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
    
    // MARK: - Leaderboard Content
    var leaderboardContent: some View {
        VStack(spacing: 40) {
            ForEach(LeaderboardType.allCases) { type in
                VStack(alignment: .leading, spacing: 20) {
                    // Section Header
                    HStack(spacing: 12) {
                        Circle()
                            .fill(type.color.opacity(0.1))
                            .frame(width: 40, height: 40)
                            .overlay(SwiftUI.Image(systemName: type.icon).foregroundColor(type.color))
                        
                        Text(type.displayName)
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 24)
                    
                    let entries = filteredEntries(discoverService.leaderboards[type] ?? [])
                    
                    if entries.isEmpty {
                        Text("Nessun dato disponibile")
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 24)
                    } else {
                        // Top 3 Podium
                        if entries.count >= 3 {
                            HStack(alignment: .bottom, spacing: 12) {
                                MinimalPodiumView(entry: entries[1], rank: 2, color: .gray)
                                MinimalPodiumView(entry: entries[0], rank: 1, color: .yellow)
                                MinimalPodiumView(entry: entries[2], rank: 3, color: .orange)
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 10)
                        }
                        
                        // List for the rest
                        LazyVStack(spacing: 0) {
                            ForEach(Array(entries.prefix(10).enumerated()), id: \.element.id) { index, entry in
                                if index > 2 || entries.count < 3 { // Show all if < 3, else start from 4th
                                    LeaderboardRow(entry: entry, rank: index + 1, color: type.color) {
                                        showingUserProfile = entry.userProfile
                                    }
                                    if index < min(9, entries.count - 1) {
                                        Divider().padding(.leading, 60)
                                    }
                                }
                            }
                        }
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(16)
                        .padding(.horizontal, 24)
                    }
                }
            }
        }
    }
    
    // MARK: - Activity Feed (Timeline)
    var exploreContent: some View {
        VStack(alignment: .leading, spacing: 24) {
             HStack {
                Text("Attività Recenti")
                    .font(.system(size: 18, weight: .bold))
            }
            .padding(.horizontal, 24)
            
            let activities = discoverService.recentActivities
            if activities.isEmpty {
                Text("Nessuna attività recente")
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 24)
            } else {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(activities.enumerated()), id: \.element.id) { index, activity in
                        TimelineActivityRow(activity: activity, isLast: index == activities.count - 1) {
                            handleActivityTap(activity: activity)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
    
    // MARK: - Discover Users
    var discoverContent: some View {
        VStack(alignment: .leading, spacing: 32) {
            // Featured
            if !discoverService.featuredUsers.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Top Giocatori")
                        .font(.system(size: 18, weight: .bold))
                        .padding(.horizontal, 24)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(discoverService.featuredUsers) { user in
                                MinimalUserCard(user: user.toUserProfile()) {
                                    showingUserProfile = user.toUserProfile()
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
            
            // New Users
            if !discoverService.newUsers.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Nuovi Arrivati")
                        .font(.system(size: 18, weight: .bold))
                        .padding(.horizontal, 24)
                    
                    LazyVStack(spacing: 0) {
                        ForEach(discoverService.newUsers.prefix(5)) { user in
                            MinimalUserRow(user: user.toUserProfile()) {
                                showingUserProfile = user.toUserProfile()
                            }
                        }
                    }
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                    .padding(.horizontal, 24)
                }
            }
        }
    }

    private func handleActivityTap(activity: UserActivity) {
        guard let userId = activity.userId else { return }
        // Simple mock profile for navigation, ideally fetch full profile
        let profile = UserProfile(
            id: String(userId),
            username: activity.username ?? "user",
            displayName: activity.displayName ?? "User",
            avatarURL: nil,
            bio: nil,
            joinDate: Date(), lastActiveDate: Date(), isVerified: false, level: 1, experience: 0,
            stats: DiscoverUserStats(totalCards: 0, totalDecks: 0, tournamentsWon: 0, tournamentsPlayed: 0, tradesToday: 0, totalTrades: 0, communityPoints: 0, achievementsUnlocked: 0),
            badges: [], favoriteCard: nil, preferredTCG: nil, location: nil, followersCount: 0, followingCount: 0, isFollowedByCurrentUser: false
        )
        showingUserProfile = profile
    }
}

// MARK: - Components

struct CommunityTabPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
             Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? .primary : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Color(.systemBackground) : Color.clear)
                .clipShape(Capsule())
                .shadow(color: isSelected ? Color.black.opacity(0.1) : .clear, radius: 4, x: 0, y: 2)
        }
    }
}



struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let rank: Int
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text("\(rank)")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: 30)
                
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 40, height: 40)
                    .overlay(Text(String(entry.userProfile.displayName.prefix(1))).bold())
                
                Text(entry.userProfile.displayName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(entry.score)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            }
            .padding(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TimelineActivityRow: View {
    let activity: UserActivity
    let isLast: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 16) {
                // Timeline Line
                VStack(spacing: 0) {
                    Circle()
                        .fill(Color.primary)
                        .frame(width: 10, height: 10)
                        .padding(.top, 6)
                    if !isLast {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .frame(width: 2)
                            .frame(maxHeight: .infinity)
                    }
                }
                .frame(width: 20)
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(activity.displayName ?? "User")
                            .font(.system(size: 15, weight: .bold))
                        Spacer()
                    }
                    
                    Text(activity.description)
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 24)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MinimalUserCard: View {
    let user: UserProfile
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Circle()
                    .fill(Color(.systemGray6))
                    .frame(width: 60, height: 60)
                    .overlay(Text(String(user.displayName.prefix(1))).font(.title3).bold())
                
                VStack(spacing: 4) {
                    Text(user.displayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Text("Lv. \(user.level)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .frame(width: 120)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MinimalUserRow: View {
    let user: UserProfile
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
             HStack(spacing: 12) {
                Circle()
                    .fill(Color(.systemGray6))
                    .frame(width: 36, height: 36)
                    .overlay(Text(String(user.displayName.prefix(1))).font(.caption).bold())
                 
                 VStack(alignment: .leading, spacing: 2) {
                     Text(user.displayName)
                         .font(.system(size: 14, weight: .medium))
                         .foregroundColor(.primary)
                     Text("Ha appena iniziato")
                         .font(.system(size: 12))
                         .foregroundColor(.secondary)
                 }
                 Spacer()
                 SwiftUI.Image(systemName: "chevron.right")
                     .font(.caption)
                     .foregroundColor(Color.gray)
             }
             .padding(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MinimalPodiumView: View {
    let entry: LeaderboardEntry
    let rank: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 0) {
            // Rank Number (Big & Bold)
            Text("\(rank)")
                .font(.system(size: rank == 1 ? 64 : 48, weight: .black, design: .rounded))
                .foregroundColor(color.opacity(0.8))
                .shadow(color: color.opacity(0.3), radius: 10, x: 0, y: 5)
                .offset(y: 10) // Overlap slightly
                .zIndex(1)
            
            // Card
            VStack(spacing: 8) {
                Text(entry.userProfile.displayName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .padding(.top, 20)
                
                Text("\(entry.score)")
                    .font(.system(size: 16, weight: .heavy, design: .monospaced))
                    .foregroundColor(color)
                
                // Optional: Tiny avatar or minimal indicator
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 8, height: 8)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)
            .padding(.bottom, 16)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}
