//
//  TournamentActivityAttributes.swift
//  TCG Arena
//
//  Shared Activity Attributes - used by both app and widget extension
//

import ActivityKit
import Foundation

// MARK: - Activity Attributes
struct TournamentActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var status: TournamentLiveStatus
        var startDate: Date
        var currentRound: Int?
        var totalRounds: Int?
    }
    
    // Static properties - don't change during activity
    var tournamentId: Int64
    var tournamentName: String
    var shopName: String
    var tcgType: String
    var tcgColor: String // Hex color string
}

// MARK: - Tournament Status
enum TournamentLiveStatus: String, Codable, Hashable {
    case upcoming = "UPCOMING"       // 60-30 min before - "Sta per iniziare"
    case countdown = "COUNTDOWN"     // 30 min countdown
    case inProgress = "IN_PROGRESS"  // Tournament started - "In corso"
    
    var displayText: String {
        switch self {
        case .upcoming: return "Sta per iniziare"
        case .countdown: return "" // Shows countdown timer instead
        case .inProgress: return "In corso"
        }
    }
    
    var icon: String {
        switch self {
        case .upcoming: return "clock.badge"
        case .countdown: return "timer"
        case .inProgress: return "gamecontroller.fill"
        }
    }
}
