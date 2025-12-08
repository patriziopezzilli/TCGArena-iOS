//
//  DiscoverModels.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/10/25.
//

import Foundation
import SwiftUI

// MARK: - User Location
struct UserLocation: Codable {
    let city: String
    let country: String
    let latitude: Double?
    let longitude: Double?
}

// MARK: - User Profile (Discover Section)
struct UserProfile: Identifiable, Codable {
    let id: String
    let username: String
    let displayName: String
    let avatarURL: String?
    let bio: String?
    let joinDate: Date
    let lastActiveDate: Date
    let isVerified: Bool
    let level: Int
    let experience: Int
    let stats: DiscoverUserStats
    let badges: [UserBadge]
    let favoriteCard: String?
    let preferredTCG: TCGType?
    let location: UserLocation?
    
    // Social stats
    let followersCount: Int
    let followingCount: Int
    let isFollowedByCurrentUser: Bool
    
    var experienceToNextLevel: Int {
        let nextLevelExp = (level + 1) * 1000
        return nextLevelExp - experience
    }
    
    var levelProgress: Double {
        let currentLevelExp = level * 1000
        let nextLevelExp = (level + 1) * 1000
        let progressInLevel = experience - currentLevelExp
        return Double(progressInLevel) / Double(nextLevelExp - currentLevelExp)
    }
}

// MARK: - User Stats (Discover Section)
struct DiscoverUserStats: Codable {
    let totalCards: Int
    let totalDecks: Int
    let tournamentsWon: Int
    let tournamentsPlayed: Int
    let tradesToday: Int
    let totalTrades: Int
    let communityPoints: Int
    let achievementsUnlocked: Int
    
    var winRate: Double {
        guard tournamentsPlayed > 0 else { return 0 }
        return Double(tournamentsWon) / Double(tournamentsPlayed)
    }
}

// MARK: - User Badge
struct UserBadge: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let iconName: String
    let color: BadgeColor
    let rarity: BadgeRarity
    let unlockedDate: Date
    
    enum BadgeColor: String, Codable {
        case bronze = "bronze"
        case silver = "silver"
        case gold = "gold"
        case platinum = "platinum"
        case diamond = "diamond"
        
        var color: Color {
            switch self {
            case .bronze: return Color.orange
            case .silver: return Color.gray
            case .gold: return Color.yellow
            case .platinum: return Color.purple
            case .diamond: return Color.cyan
            }
        }
    }
    
    enum BadgeRarity: String, Codable, CaseIterable {
        case common = "Common"
        case rare = "Rare"
        case epic = "Epic"
        case legendary = "Legendary"
    }
}

// MARK: - Leaderboard Entry
struct LeaderboardEntry: Identifiable, Codable {
    let id: String
    let userProfile: UserProfile
    let rank: Int
    let score: Int
    let change: LeaderboardChange?
    
    struct LeaderboardChange: Codable {
        let previousRank: Int
        let rankChange: Int // positive = moved up, negative = moved down
        let isNew: Bool
        
        var changeType: ChangeType {
            if isNew { return .new }
            if rankChange > 0 { return .up }
            if rankChange < 0 { return .down }
            return .same
        }
        
        enum ChangeType {
            case up, down, same, new
            
            var color: Color {
                switch self {
                case .up: return .green
                case .down: return .red
                case .same: return .secondary
                case .new: return .blue
                }
            }
            
            var icon: String {
                switch self {
                case .up: return "arrow.up"
                case .down: return "arrow.down"
                case .same: return "minus"
                case .new: return "star.fill"
                }
            }
        }
    }
}

// MARK: - Leaderboard Type
enum LeaderboardType: String, CaseIterable, Identifiable {
    case tournaments = "tournaments"
    case collection = "collection"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .tournaments: return "Tournaments"
        case .collection: return "Collection"
        }
    }
    
    var icon: String {
        switch self {
        case .tournaments: return "trophy.fill"
        case .collection: return "square.stack.3d.up.fill"
        }
    }
    
    var description: String {
        switch self {
        case .tournaments: return "Tournament wins"
        case .collection: return "Card collection size"
        }
    }
    
    var color: Color {
        switch self {
        case .tournaments: return .orange
        case .collection: return .blue
        }
    }
}

// MARK: - Discover Section Data
struct DiscoverSection: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let users: [UserProfile]
}
