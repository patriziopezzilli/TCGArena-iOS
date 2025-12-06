//
//  LeaderboardView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/22/25.
//

import SwiftUI

struct LeaderboardView: View {
    @State private var leaderboard: [UserStats] = []
    @State private var activePlayersLeaderboard: [UserStats] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            if isLoading {
                ProgressView()
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    SwiftUI.Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                    Text(error)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    Button("Retry") {
                        loadLeaderboards()
                    }
                }
                .padding()
            } else {
                VStack(spacing: 0) {
                    // Custom Segmented Control
                    HStack(spacing: 0) {
                        LeaderboardSegmentButton(title: "Overall", isSelected: selectedTab == 0) { selectedTab = 0 }
                        LeaderboardSegmentButton(title: "Active Players", isSelected: selectedTab == 1) { selectedTab = 1 }
                    }
                    .padding(4)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            let currentList = selectedTab == 0 ? leaderboard : activePlayersLeaderboard
                            
                            if currentList.isEmpty {
                                EmptyStateView(
                                    icon: "chart.bar.xaxis",
                                    title: "No Data",
                                    message: "Leaderboard is currently empty."
                                )
                                .padding(.top, 40)
                            } else {
                                // Top 3 Podium
                                if currentList.count >= 3 {
                                    HStack(alignment: .bottom, spacing: 16) {
                                        PodiumItem(user: currentList[1], rank: 2)
                                        PodiumItem(user: currentList[0], rank: 1)
                                        PodiumItem(user: currentList[2], rank: 3)
                                    }
                                    .padding(.top, 20)
                                    .padding(.horizontal, 20)
                                }
                                
                                // Rest of the list
                                LazyVStack(spacing: 12) {
                                    ForEach(Array(currentList.dropFirst(3).enumerated()), id: \.element.id) { index, userStats in
                                        LeaderboardListItem(rank: index + 4, userStats: userStats)
                                    }
                                }
                                .padding(20)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            loadLeaderboards()
        }
    }
    
    private func loadLeaderboards() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                async let leaderboardTask = UserService.shared.getLeaderboard()
                async let activeTask = UserService.shared.getActivePlayersLeaderboard()
                
                let (leaderboard, activePlayers) = try await (leaderboardTask, activeTask)
                
                await MainActor.run {
                    self.leaderboard = leaderboard
                    self.activePlayersLeaderboard = activePlayers
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

struct LeaderboardSegmentButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .primary : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color(.systemBackground) : Color.clear)
                        .shadow(color: Color.black.opacity(isSelected ? 0.1 : 0), radius: 2, x: 0, y: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PodiumItem: View {
    let user: UserStats
    let rank: Int
    
    var body: some View {
        VStack(spacing: 8) {
            // Avatar
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.2))
                    .frame(width: rank == 1 ? 80 : 60, height: rank == 1 ? 80 : 60)
                
                Text(String(user.user.username.prefix(1)).uppercased())
                    .font(.system(size: rank == 1 ? 32 : 24, weight: .bold))
                    .foregroundColor(rankColor)
                
                // Rank Badge
                VStack {
                    Spacer()
                    Text("\(rank)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(rankColor))
                        .offset(y: 12)
                }
            }
            .frame(height: rank == 1 ? 90 : 70)
            .zIndex(1)
            
            // Info
            VStack(spacing: 4) {
                Text(user.user.username)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text("\(user.totalWins) Wins")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 12)
            .padding(.horizontal, 8)
            .padding(.bottom, 12)
            .frame(width: rank == 1 ? 110 : 90)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .blue
        }
    }
}

struct LeaderboardListItem: View {
    let rank: Int
    let userStats: UserStats
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank
            Text("\(rank)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.secondary)
                .frame(width: 30)
            
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Text(String(userStats.user.username.prefix(1)).uppercased())
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.blue)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(userStats.user.username)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(userStats.favoriteTCGType.flatMap { TCGType(rawValue: $0)?.displayName } ?? "TCG Player")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Stats
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(userStats.totalWins) Wins")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(String(format: "%.0f%% Win Rate", userStats.winRate * 100))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    LeaderboardView()
}