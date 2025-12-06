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
    let partner: Partner?
    let type: RewardType

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case costPoints
        case imageUrl
        case isActive
        case createdAt
        case partner
        case type
    }
}

enum RewardType: String, Codable {
    case physical = "PHYSICAL"
    case digital = "DIGITAL"
    
    var displayName: String {
        switch self {
        case .physical: return "Physical"
        case .digital: return "Digital"
        }
    }
    
    var icon: String {
        switch self {
        case .physical: return "shippingbox.fill"
        case .digital: return "wifi"
        }
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