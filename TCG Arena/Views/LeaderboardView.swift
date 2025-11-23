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
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading leaderboard...")
                } else if let error = errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                } else {
                    Picker("Leaderboard Type", selection: $selectedTab) {
                        Text("Overall").tag(0)
                        Text("Active Players").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)

                    if selectedTab == 0 {
                        leaderboardList(leaderboard, title: "Overall Leaderboard")
                    } else {
                        leaderboardList(activePlayersLeaderboard, title: "Active Players Leaderboard")
                    }
                }
            }
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadLeaderboards()
            }
        }
    }

    private func leaderboardList(_ stats: [UserStats], title: String) -> some View {
        List {
            Section(header: Text(title)) {
                ForEach(stats.indices, id: \.self) { index in
                    LeaderboardRow(rank: index + 1, userStats: stats[index])
                }
            }
        }
        .listStyle(PlainListStyle())
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

struct LeaderboardRow: View {
    let rank: Int
    let userStats: UserStats

    var body: some View {
        HStack(spacing: 12) {
            // Rank
            ZStack {
                Circle()
                    .fill(rankColor(for: rank))
                    .frame(width: 40, height: 40)

                Text("\(rank)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }

            // User Info
            VStack(alignment: .leading, spacing: 4) {
                Text(userStats.favoriteTCGType ?? "TCG Player")
                    .font(.headline)
                    .foregroundColor(.primary)

                HStack(spacing: 12) {
                    StatItem(label: "Wins", value: "\(userStats.totalWins)")
                    StatItem(label: "Win Rate", value: String(format: "%.1f%%", userStats.winRate * 100))
                    StatItem(label: "Tournaments", value: "\(userStats.totalTournaments)")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()

            // Trophy for top 3
            if rank <= 3 {
                SwiftUI.Image(systemName: "trophy.fill")
                    .foregroundColor(rankColor(for: rank))
                    .font(.title2)
            }
        }
        .padding(.vertical, 8)
    }

    private func rankColor(for rank: Int) -> Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return Color.blue.opacity(0.3)
        }
    }
}

struct StatItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 12, weight: .semibold))
            Text(label)
                .font(.system(size: 10))
        }
    }
}

#Preview {
    LeaderboardView()
}