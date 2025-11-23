//
//  RewardModels.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/22/25.
//

import Foundation

struct Reward: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String
    let costPoints: Int
    let imageUrl: String?
    let isActive: Bool
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case costPoints = "cost_points"
        case imageUrl = "image_url"
        case isActive = "is_active"
        case createdAt = "created_at"
    }
}

struct RewardTransaction: Codable, Identifiable {
    let id: Int
    let userId: Int
    let pointsChange: Int
    let description: String
    let rewardId: Int?
    let timestamp: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case pointsChange = "points_change"
        case description
        case rewardId = "reward_id"
        case timestamp
    }
}

struct UserPoints: Codable {
    let points: Int
}