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
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading achievements...")
                } else if let error = errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // User achievements section
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Your Achievements")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                if userAchievements.isEmpty {
                                    Text("No achievements unlocked yet. Keep playing to earn them!")
                                        .foregroundColor(.secondary)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(10)
                                } else {
                                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                                        ForEach(userAchievements, id: \.id) { userAchievement in
                                            if let achievement = achievements.first(where: { $0.id == userAchievement.achievementId }) {
                                                AchievementCard(achievement: achievement, isUnlocked: true, unlockedAt: userAchievement.unlockedAt)
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Available achievements section
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Available Achievements")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                                    ForEach(achievements.filter { achievement in
                                        !userAchievements.contains(where: { $0.achievementId == achievement.id })
                                    }) { achievement in
                                        AchievementCard(achievement: achievement, isUnlocked: false, unlockedAt: nil)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadAchievements()
            }
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
}

struct AchievementCard: View {
    let achievement: Achievement
    let isUnlocked: Bool
    let unlockedAt: String?
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? Color.yellow.opacity(0.2) : Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                SwiftUI.Image(systemName: achievement.iconUrl ?? "star")
                    .font(.system(size: 24))
                    .foregroundColor(isUnlocked ? .yellow : .gray)
            }
            
            Text(achievement.name)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(isUnlocked ? .primary : .secondary)
            
            Text(achievement.description)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            if isUnlocked {
                Text("+\(achievement.pointsReward) pts")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                
                if let unlockedAt = unlockedAt {
                    Text("Unlocked: \(formatDate(unlockedAt))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                Text(achievement.criteria)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .opacity(isUnlocked ? 1.0 : 0.6)
    }
    
    private func formatDate(_ dateString: String) -> String {
        return String(dateString.prefix(10))
    }
}

#Preview {
    AchievementView()
        .environmentObject(AchievementService.shared)
}