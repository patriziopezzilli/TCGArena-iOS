//
//  EmbeddedUserStats.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/7/25.
//

import Foundation

/// Struct matching backend UserStatsDTO for embedded stats in User responses
struct EmbeddedUserStats: Codable {
    let totalCards: Int
    let totalDecks: Int
    let tournamentsPlayed: Int
    let tournamentsWon: Int
    let winRate: Double
    
    enum CodingKeys: String, CodingKey {
        case totalCards
        case totalDecks
        case tournamentsPlayed
        case tournamentsWon
        case winRate
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        totalCards = try container.decodeIfPresent(Int.self, forKey: .totalCards) ?? 0
        totalDecks = try container.decodeIfPresent(Int.self, forKey: .totalDecks) ?? 0
        tournamentsPlayed = try container.decodeIfPresent(Int.self, forKey: .tournamentsPlayed) ?? 0
        tournamentsWon = try container.decodeIfPresent(Int.self, forKey: .tournamentsWon) ?? 0
        winRate = try container.decodeIfPresent(Double.self, forKey: .winRate) ?? 0.0
    }
    
    init(totalCards: Int = 0, totalDecks: Int = 0, tournamentsPlayed: Int = 0, tournamentsWon: Int = 0, winRate: Double = 0.0) {
        self.totalCards = totalCards
        self.totalDecks = totalDecks
        self.tournamentsPlayed = tournamentsPlayed
        self.tournamentsWon = tournamentsWon
        self.winRate = winRate
    }
}
