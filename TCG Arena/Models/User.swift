//
//  User.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/5/25.
//

import Foundation

struct User: Identifiable, Codable {
    let id: Int64
    let email: String
    let username: String
    let displayName: String
    let profileImageUrl: String?
    let dateJoined: Date
    let isPremium: Bool
    let isMerchant: Bool
    let shopId: Int64?
    let favoriteGame: TCGType?
    let location: UserLocation?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case username
        case displayName = "display_name"
        case profileImageUrl = "profile_image_url"
        case dateJoined = "date_joined"
        case isPremium = "is_premium"
        case isMerchant = "is_merchant"
        case shopId = "shop_id"
        case favoriteGame = "favorite_game"
        case location
    }
    
    // Custom decoder per gestire la conversione da LocalDateTime a Date
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int64.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        username = try container.decode(String.self, forKey: .username)
        displayName = try container.decode(String.self, forKey: .displayName)
        profileImageUrl = try container.decodeIfPresent(String.self, forKey: .profileImageUrl)
        isPremium = try container.decode(Bool.self, forKey: .isPremium)
        isMerchant = try container.decode(Bool.self, forKey: .isMerchant)
        shopId = try container.decodeIfPresent(Int64.self, forKey: .shopId)
        favoriteGame = try container.decodeIfPresent(TCGType.self, forKey: .favoriteGame)
        location = try container.decodeIfPresent(UserLocation.self, forKey: .location)
        
        // Gestisci la conversione della data
        if let dateString = try? container.decode(String.self, forKey: .dateJoined) {
            let formatter = ISO8601DateFormatter()
            dateJoined = formatter.date(from: dateString) ?? Date()
        } else {
            dateJoined = Date()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(email, forKey: .email)
        try container.encode(username, forKey: .username)
        try container.encode(displayName, forKey: .displayName)
        try container.encodeIfPresent(profileImageUrl, forKey: .profileImageUrl)
        try container.encode(isPremium, forKey: .isPremium)
        try container.encode(isMerchant, forKey: .isMerchant)
        try container.encodeIfPresent(shopId, forKey: .shopId)
        try container.encodeIfPresent(favoriteGame, forKey: .favoriteGame)
        try container.encodeIfPresent(location, forKey: .location)
        
        let formatter = ISO8601DateFormatter()
        try container.encode(formatter.string(from: dateJoined), forKey: .dateJoined)
    }
    
    func toUserProfile() -> UserProfile {
        return UserProfile(
            id: String(id),
            username: username,
            displayName: displayName,
            avatarURL: profileImageUrl,
            bio: nil,
            joinDate: dateJoined,
            lastActiveDate: dateJoined,
            isVerified: false,
            level: 1,
            experience: 0,
            stats: DiscoverUserStats(totalCards: 0, totalDecks: 0, tournamentsWon: 0, tournamentsPlayed: 0, tradesToday: 0, totalTrades: 0, communityPoints: 0, achievementsUnlocked: 0),
            badges: [],
            favoriteCard: nil,
            preferredTCG: favoriteGame,
            location: location,
            followersCount: 0,
            followingCount: 0,
            isFollowedByCurrentUser: false
        )
    }
}