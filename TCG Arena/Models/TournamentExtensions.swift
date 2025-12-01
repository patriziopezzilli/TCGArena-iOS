//
//  TournamentExtensions.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/1/25.
//

import Foundation

// MARK: - Match
/// Represents a match in a tournament
struct Match: Identifiable, Codable, Hashable {
    let id: String
    let tournamentId: String
    let round: Int
    let player1Id: String
    let player2Id: String
    var result: MatchResult
    var score: String?
    let createdAt: Date
    let updatedAt: Date
    
    // Optional embedded data
    var player1: User?
    var player2: User?
    var tournament: Tournament?
    
    enum MatchResult: String, Codable, CaseIterable {
        case pending = "PENDING"
        case player1Win = "P1_WIN"
        case player2Win = "P2_WIN"
        case draw = "DRAW"
        
        var displayName: String {
            switch self {
            case .pending: return "Pending"
            case .player1Win: return "Player 1 Win"
            case .player2Win: return "Player 2 Win"
            case .draw: return "Draw"
            }
        }
        
        var shortName: String {
            switch self {
            case .pending: return "-"
            case .player1Win: return "P1"
            case .player2Win: return "P2"
            case .draw: return "Draw"
            }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case tournamentId = "tournament_id"
        case round
        case player1Id = "player1_id"
        case player2Id = "player2_id"
        case result, score
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    var isPending: Bool {
        result == .pending
    }
    
    var winner: String? {
        switch result {
        case .player1Win: return player1Id
        case .player2Win: return player2Id
        case .draw, .pending: return nil
        }
    }
    
    func isPlayer(_ userId: String) -> Bool {
        player1Id == userId || player2Id == userId
    }
    
    func opponent(for userId: String) -> String? {
        if player1Id == userId {
            return player2Id
        } else if player2Id == userId {
            return player1Id
        }
        return nil
    }
}

// MARK: - Tournament Registration
/// Represents a user's registration for a tournament
struct TournamentRegistration: Identifiable, Codable, Hashable {
    let id: String
    let tournamentId: String
    let userId: String
    var status: RegistrationStatus
    let decklistSubmitted: Bool
    let checkInTime: Date?
    let registeredAt: Date
    
    // Optional embedded data
    var user: User?
    var tournament: Tournament?
    
    enum RegistrationStatus: String, Codable, CaseIterable {
        case registered = "REGISTERED"
        case checkedIn = "CHECKED_IN"
        case dropped = "DROPPED"
        case eliminated = "ELIMINATED"
        case disqualified = "DISQUALIFIED"
        
        var displayName: String {
            switch self {
            case .registered: return "Registered"
            case .checkedIn: return "Checked In"
            case .dropped: return "Dropped"
            case .eliminated: return "Eliminated"
            case .disqualified: return "Disqualified"
            }
        }
        
        var color: String {
            switch self {
            case .registered: return "blue"
            case .checkedIn: return "green"
            case .dropped: return "orange"
            case .eliminated: return "gray"
            case .disqualified: return "red"
            }
        }
        
        var icon: String {
            switch self {
            case .registered: return "person.crop.circle.badge.checkmark"
            case .checkedIn: return "checkmark.circle.fill"
            case .dropped: return "person.crop.circle.badge.xmark"
            case .eliminated: return "xmark.circle"
            case .disqualified: return "exclamationmark.triangle.fill"
            }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case tournamentId = "tournament_id"
        case userId = "user_id"
        case status
        case decklistSubmitted = "decklist_submitted"
        case checkInTime = "check_in_time"
        case registeredAt = "registered_at"
    }
    
    var isActive: Bool {
        status == .registered || status == .checkedIn
    }
    
    var canDrop: Bool {
        status == .registered || status == .checkedIn
    }
    
    var canCheckIn: Bool {
        status == .registered
    }
}

// MARK: - Tournament Round
/// Represents a round in a tournament
struct TournamentRound: Identifiable, Codable, Hashable {
    let id: String
    let tournamentId: String
    let roundNumber: Int
    let matches: [Match]
    let status: RoundStatus
    let startTime: Date?
    let endTime: Date?
    
    enum RoundStatus: String, Codable {
        case pending = "PENDING"
        case inProgress = "IN_PROGRESS"
        case completed = "COMPLETED"
        
        var displayName: String {
            switch self {
            case .pending: return "Pending"
            case .inProgress: return "In Progress"
            case .completed: return "Completed"
            }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case tournamentId = "tournament_id"
        case roundNumber = "round_number"
        case matches, status
        case startTime = "start_time"
        case endTime = "end_time"
    }
    
    var allMatchesCompleted: Bool {
        matches.allSatisfy { !$0.isPending }
    }
}

// MARK: - Standings
/// Represents a player's standing in a tournament
struct TournamentStanding: Identifiable, Codable, Hashable {
    let id: String
    let tournamentId: String
    let userId: String
    let rank: Int
    let wins: Int
    let losses: Int
    let draws: Int
    let points: Int
    let opponentMatchWinPercentage: Double?
    let gameWinPercentage: Double?
    
    // Optional embedded data
    var user: User?
    
    enum CodingKeys: String, CodingKey {
        case id
        case tournamentId = "tournament_id"
        case userId = "user_id"
        case rank, wins, losses, draws, points
        case opponentMatchWinPercentage = "omw_percentage"
        case gameWinPercentage = "gw_percentage"
    }
    
    var matchesPlayed: Int {
        wins + losses + draws
    }
    
    var winRate: Double {
        guard matchesPlayed > 0 else { return 0 }
        return Double(wins) / Double(matchesPlayed)
    }
    
    var record: String {
        "\(wins)-\(losses)-\(draws)"
    }
}

// MARK: - Tournament DTOs
struct CreateMatchResultRequest: Codable {
    let matchId: String
    let result: Match.MatchResult
    let score: String?
    
    enum CodingKeys: String, CodingKey {
        case matchId = "match_id"
        case result, score
    }
}

struct StartTournamentRequest: Codable {
    let tournamentId: String
    
    enum CodingKeys: String, CodingKey {
        case tournamentId = "tournament_id"
    }
}

struct CreateRoundRequest: Codable {
    let tournamentId: String
    
    enum CodingKeys: String, CodingKey {
        case tournamentId = "tournament_id"
    }
}

struct DropFromTournamentRequest: Codable {
    let reason: String?
}

struct CheckInRequest: Codable {
    let decklistUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case decklistUrl = "decklist_url"
    }
}

// MARK: - Response DTOs
struct TournamentDetailResponse: Codable {
    let tournament: Tournament
    let registrations: [TournamentRegistration]
    let currentRound: TournamentRound?
    let standings: [TournamentStanding]
}

struct MatchPairingResponse: Codable {
    let round: TournamentRound
    let userMatch: Match?
}

struct StandingsResponse: Codable {
    let standings: [TournamentStanding]
    let updated: Date
    
    enum CodingKeys: String, CodingKey {
        case standings
        case updated = "updated_at"
    }
}
