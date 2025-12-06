//
//  AchievementView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/22/25.
//

import SwiftUI

struct AchievementView: View {
    @EnvironmentObject var achievementService: AchievementService
    @State private var achievements: [Achievement] = []
    @State private var userAchievements: [UserAchievement] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
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
                        loadAchievements()
                    }
                }
                .padding()
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // Progress Header
                        AchievementProgressHeader(
                            total: achievements.count,
                            unlocked: userAchievements.count,
                            points: calculateTotalPoints()
                        )
                        
                        // Recent Unlocks
                        if !userAchievements.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                AchievementSectionHeader(title: "Recent Unlocks", subtitle: "Your latest triumphs")
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(getRecentUnlocks()) { userAchievement in
                                            if let achievement = achievements.first(where: { $0.id == userAchievement.achievementId }) {
                                                RecentUnlockCard(achievement: achievement, unlockedAt: userAchievement.unlockedAt)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                        
                        // All Achievements
                        VStack(alignment: .leading, spacing: 16) {
                            AchievementSectionHeader(title: "All Achievements", subtitle: "Collect them all")
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 16) {
                                ForEach(achievements) { achievement in
                                    let isUnlocked = userAchievements.contains(where: { $0.achievementId == achievement.id })
                                    AchievementGridItem(achievement: achievement, isUnlocked: isUnlocked)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            loadAchievements()
        }
    }
    
    private func loadAchievements() {
        isLoading = true
        errorMessage = nil
        
        let group = DispatchGroup()
        var loadedAchievements: [Achievement] = []
        var loadedUserAchievements: [UserAchievement] = []
        
        group.enter()
        achievementService.getAllActiveAchievements { result in
            switch result {
            case .success(let achievements):
                loadedAchievements = achievements
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
            group.leave()
        }
        
        group.enter()
        achievementService.getUserAchievements { result in
            switch result {
            case .success(let userAchievements):
                loadedUserAchievements = userAchievements
            case .failure(let error):
                self.errorMessage = (self.errorMessage ?? "") + "\n" + error.localizedDescription
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            self.achievements = loadedAchievements
            self.userAchievements = loadedUserAchievements
            self.isLoading = false
        }
    }
    
    private func calculateTotalPoints() -> Int {
        var total = 0
        for userAchievement in userAchievements {
            if let achievement = achievements.first(where: { $0.id == userAchievement.achievementId }) {
                total += achievement.pointsReward
            }
        }
        return total
    }
    
    private func getRecentUnlocks() -> [UserAchievement] {
        // Sort by unlockedAt desc
        return userAchievements.sorted { $0.unlockedAt > $1.unlockedAt }.prefix(5).map { $0 }
    }
}

struct AchievementProgressHeader: View {
    let total: Int
    let unlocked: Int
    let points: Int
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Progress")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    Text("\(unlocked) of \(total) unlocked")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    SwiftUI.Image(systemName: "star.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.yellow)
                    Text("\(points) pts")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(20)
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    Capsule()
                        .fill(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                        .frame(width: total > 0 ? geometry.size.width * CGFloat(unlocked) / CGFloat(total) : 0, height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .padding(.horizontal, 20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct RecentUnlockCard: View {
    let achievement: Achievement
    let unlockedAt: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                SwiftUI.Image(systemName: achievement.iconUrl ?? "star.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.yellow)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text("Unlocked \(formatDate(unlockedAt))")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .frame(width: 200, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
    
    private func formatDate(_ dateString: String) -> String {
        return String(dateString.prefix(10))
    }
}

struct AchievementGridItem: View {
    let achievement: Achievement
    let isUnlocked: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? Color.yellow.opacity(0.1) : Color.gray.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                SwiftUI.Image(systemName: achievement.iconUrl ?? "star.fill")
                    .font(.system(size: 24))
                    .foregroundColor(isUnlocked ? .yellow : .gray)
            }
            
            VStack(spacing: 4) {
                Text(achievement.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(isUnlocked ? .primary : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Text(achievement.description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            
            if isUnlocked {
                Text("+\(achievement.pointsReward) pts")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.green)
            } else {
                Text("Locked")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
        .opacity(isUnlocked ? 1.0 : 0.7)
        .grayscale(isUnlocked ? 0.0 : 1.0)
    }
}

struct AchievementSectionHeader: View {
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

#Preview {
    AchievementView()
        .environmentObject(AchievementService.shared)
}