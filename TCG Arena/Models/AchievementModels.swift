//
//  AchievementModels.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/22/25.
//

import Foundation

struct Achievement: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String
    let iconUrl: String?
    let criteria: String
    let pointsReward: Int
    let isActive: Bool
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case iconUrl = "icon_url"
        case criteria
        case pointsReward = "points_reward"
        case isActive = "is_active"
        case createdAt = "created_at"
    }
}

struct UserAchievement: Codable, Identifiable {
    let id: Int
    let userId: Int
    let achievementId: Int
    let unlockedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case achievementId = "achievement_id"
        case unlockedAt = "unlocked_at"
    }
}