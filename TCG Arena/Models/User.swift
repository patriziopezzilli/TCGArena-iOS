//
//  User.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/5/25.
//

import Foundation

// Helper struct per decodificare favorite_games dal backend
struct UserFavoriteTCG: Codable {
    let id: Int64?
    let tcgType: TCGType
}

struct User: Identifiable, Codable {
    let id: Int64
    let email: String
    let username: String
    let displayName: String
    let profileImageUrl: String?
    let dateJoined: String
    let isPremium: Bool
    let isMerchant: Bool
    let shopId: Int64?
    let points: Int?
    let favoriteTCGTypesString: String?
    let deviceToken: String?
    let favoriteGame: TCGType?
    let favoriteGames: [TCGType]?
    let location: UserLocation?
    let stats: EmbeddedUserStats?  // Stats embedded from backend
    
    // Chiave privata per decodificare l'array di oggetti dal backend
    private enum FavoriteGamesKeys: String, CodingKey {
        case favoriteGamesObjects = "favorite_games"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case username
        case displayName
        case profileImageUrl
        case dateJoined
        case isPremium
        case isMerchant
        case shopId
        case points
        case favoriteTCGTypesString
        case deviceToken
        case favoriteGame = "favorite_game"
        case favoriteGames = "favorite_games"
        case location
        case stats
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
        points = try container.decodeIfPresent(Int.self, forKey: .points)
        favoriteTCGTypesString = try container.decodeIfPresent(String.self, forKey: .favoriteTCGTypesString)
        deviceToken = try container.decodeIfPresent(String.self, forKey: .deviceToken)
        favoriteGame = try container.decodeIfPresent(TCGType.self, forKey: .favoriteGame)

        // Decodifica favorite_games come array di oggetti UserFavoriteTCG
        if let favoriteGamesObjects = try? container.decodeIfPresent([UserFavoriteTCG].self, forKey: .favoriteGames) {
            favoriteGames = favoriteGamesObjects.map { $0.tcgType }
        } else {
            // Fallback: prova a decodificare come array semplice di TCGType
            favoriteGames = try container.decodeIfPresent([TCGType].self, forKey: .favoriteGames)
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

        // Gestisci la data come stringa (formattata dal backend)
        if let dateString = try? container.decode(String.self, forKey: .dateJoined) {
            dateJoined = dateString
        } else if let jsonContainer = try? decoder.container(keyedBy: DynamicCodingKeys.self),
                  let dateString = try? jsonContainer.decode(String.self, forKey: DynamicCodingKeys(stringValue: "dateJoined")!) {
            dateJoined = dateString
        } else {
            // Fallback: usa data corrente formattata
            let formatter = DateFormatter()
            formatter.dateFormat = "dd MMM yyyy, HH:mm"
            dateJoined = formatter.string(from: Date())
        }
        
        // Decode embedded stats from backend
        stats = try container.decodeIfPresent(EmbeddedUserStats.self, forKey: .stats)
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
        try container.encodeIfPresent(points, forKey: .points)
        try container.encodeIfPresent(favoriteTCGTypesString, forKey: .favoriteTCGTypesString)
        try container.encodeIfPresent(deviceToken, forKey: .deviceToken)
        try container.encodeIfPresent(favoriteGame, forKey: .favoriteGame)
        try container.encodeIfPresent(favoriteGames, forKey: .favoriteGames)
        try container.encodeIfPresent(location, forKey: .location)
        try container.encodeIfPresent(stats, forKey: .stats)
        
        // La data è già una stringa formattata dal backend
        try container.encode(dateJoined, forKey: .dateJoined)
    }
    
    func toUserProfile() -> UserProfile {
        // Convert dateJoined string to Date
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy, HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let joinDate = formatter.date(from: dateJoined) ?? Date()
        
        // Use real stats from backend if available, otherwise estimate from points
        let userStats: DiscoverUserStats
        if let backendStats = stats {
            // Use real stats from backend
            userStats = DiscoverUserStats(
                totalCards: backendStats.totalCards,
                totalDecks: backendStats.totalDecks,
                tournamentsWon: backendStats.tournamentsWon,
                tournamentsPlayed: backendStats.tournamentsPlayed,
                tradesToday: 0,
                totalTrades: 0,
                communityPoints: points ?? 0,
                achievementsUnlocked: 0
            )
        } else {
            // Fallback: estimate from points
            let userPoints = points ?? 0
            userStats = DiscoverUserStats(
                totalCards: userPoints / 10,
                totalDecks: userPoints / 50,
                tournamentsWon: userPoints / 100,
                tournamentsPlayed: userPoints / 50,
                tradesToday: 0,
                totalTrades: userPoints / 30,
                communityPoints: userPoints,
                achievementsUnlocked: userPoints / 200
            )
        }

        return UserProfile(
            id: String(id),
            username: username,
            displayName: displayName,
            avatarURL: profileImageUrl,
            bio: nil,
            joinDate: joinDate,
            lastActiveDate: joinDate,
            isVerified: false,
            level: max(1, (points ?? 0) / 100),
            experience: points ?? 0,
            stats: userStats,
            badges: [],
            favoriteCard: nil,
            preferredTCG: favoriteGames?.first ?? favoriteGame,
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