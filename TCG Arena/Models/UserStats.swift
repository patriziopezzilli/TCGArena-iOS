//
//  UserStats.swift
//  TCG Arena
//
//  Created by Assistant on 22/11/2024.
//

import Foundation

struct UserStats: Codable {
    let totalCards: Int
    let totalDecks: Int
    let totalTournaments: Int
    let totalWins: Int
    let totalLosses: Int
    let winRate: Double
    let favoriteTCGType: String?
    let joinDate: String
    let lastActivity: String?

    enum CodingKeys: String, CodingKey {
        case totalCards
        case totalDecks
        case totalTournaments
        case totalWins
        case totalLosses
        case winRate
        case favoriteTCGType
        case joinDate
        case lastActivity
    }
}