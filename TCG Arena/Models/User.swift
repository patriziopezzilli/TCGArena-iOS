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
    // Custom decoder per gestire la conversione da LocalDateTime a Date
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int64.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        username = try container.decode(String.self, forKey: .username)
        
        // Il backend può restituire sia "displayName" che "display_name"
        if let name = try? container.decode(String.self, forKey: .displayName) {
            displayName = name
        } else if let jsonContainer = try? decoder.container(keyedBy: DynamicCodingKeys.self),
                  let name = try? jsonContainer.decode(String.self, forKey: DynamicCodingKeys(stringValue: "displayName")!) {
            displayName = name
        } else {
            displayName = username // fallback
        }
        
        // Gestisci profileImageUrl (può essere "profileImageUrl" o "profile_image_url")
        if let url = try? container.decodeIfPresent(String.self, forKey: .profileImageUrl) {
            profileImageUrl = url
        } else if let jsonContainer = try? decoder.container(keyedBy: DynamicCodingKeys.self),
                  let url = try? jsonContainer.decodeIfPresent(String.self, forKey: DynamicCodingKeys(stringValue: "profileImageUrl")!) {
            profileImageUrl = url
        } else {
            profileImageUrl = nil
        }
        
        // Gestisci isPremium (può essere "isPremium" o "is_premium")
        if let premium = try? container.decode(Bool.self, forKey: .isPremium) {
            isPremium = premium
        } else if let jsonContainer = try? decoder.container(keyedBy: DynamicCodingKeys.self),
                  let premium = try? jsonContainer.decode(Bool.self, forKey: DynamicCodingKeys(stringValue: "isPremium")!) {
            isPremium = premium
        } else {
            isPremium = false
        }
        
        // Gestisci isMerchant (può essere "isMerchant" o "is_merchant")
        if let merchant = try? container.decode(Bool.self, forKey: .isMerchant) {
            isMerchant = merchant
        } else if let jsonContainer = try? decoder.container(keyedBy: DynamicCodingKeys.self),
                  let merchant = try? jsonContainer.decode(Bool.self, forKey: DynamicCodingKeys(stringValue: "isMerchant")!) {
            isMerchant = merchant
        } else {
            isMerchant = false
        }
        
        // Gestisci shopId (può essere "shopId" o "shop_id")
        if let shop = try? container.decodeIfPresent(Int64.self, forKey: .shopId) {
            shopId = shop
        } else if let jsonContainer = try? decoder.container(keyedBy: DynamicCodingKeys.self),
                  let shop = try? jsonContainer.decodeIfPresent(Int64.self, forKey: DynamicCodingKeys(stringValue: "shopId")!) {
            shopId = shop
        } else {
            shopId = nil
        }
        
        // Gestisci favoriteGame (può essere "favoriteGame" o "favorite_game")
        if let game = try? container.decodeIfPresent(TCGType.self, forKey: .favoriteGame) {
            favoriteGame = game
        } else if let jsonContainer = try? decoder.container(keyedBy: DynamicCodingKeys.self),
                  let game = try? jsonContainer.decodeIfPresent(TCGType.self, forKey: DynamicCodingKeys(stringValue: "favoriteGame")!) {
            favoriteGame = game
        } else {
            favoriteGame = nil
        }
        
        // Gestisci location
        if let loc = try? container.decodeIfPresent(UserLocation.self, forKey: .location) {
            location = loc
        } else if let jsonContainer = try? decoder.container(keyedBy: DynamicCodingKeys.self),
                  let loc = try? jsonContainer.decodeIfPresent(UserLocation.self, forKey: DynamicCodingKeys(stringValue: "location")!) {
            location = loc
        } else {
            location = nil
        }
        
        // Gestisci la conversione della data (può essere "dateJoined" o "date_joined")
        if let dateString = try? container.decode(String.self, forKey: .dateJoined) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            dateJoined = formatter.date(from: dateString) ?? Date()
        } else if let jsonContainer = try? decoder.container(keyedBy: DynamicCodingKeys.self),
                  let dateString = try? jsonContainer.decode(String.self, forKey: DynamicCodingKeys(stringValue: "dateJoined")!) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
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

// Helper per decodificare chiavi dinamiche
struct DynamicCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}