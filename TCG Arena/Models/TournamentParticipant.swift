//
//  TournamentParticipant.swift
//  TCG Arena
//
//  Created by Assistant on 22/11/2024.
//

import Foundation

struct TournamentParticipant: Identifiable, Codable {
    let id: Int64
    let tournamentId: Int64
    let userId: Int64
    let registrationDate: String
    let hasPaid: Bool
    let status: ParticipantStatus
    let placement: Int?
    let checkedInAt: String?
    let checkInCode: String?

    enum CodingKeys: String, CodingKey {
        case id
        case tournamentId
        case userId
        case registrationDate
        case hasPaid
        case status
        case placement
        case checkedInAt
        case checkInCode
    }
    
    var isCheckedIn: Bool {
        return checkedInAt != nil
    }
    
    var checkedInDate: Date? {
        guard let checkedInAt = checkedInAt else { return nil }
        return ISO8601DateFormatter().date(from: checkedInAt)
    }
    
    var registrationDateFormatted: Date? {
        return ISO8601DateFormatter().date(from: registrationDate)
    }
    
    var placementBadge: String? {
        guard let p = placement else { return nil }
        switch p {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return nil
        }
    }
}

enum ParticipantStatus: String, Codable {
    case REGISTERED = "REGISTERED"
    case WAITING_LIST = "WAITING_LIST"
    case CHECKED_IN = "CHECKED_IN"
    case CANCELLED = "CANCELLED"
}

// MARK: - Tournament Participant with User Details
struct TournamentParticipantWithUser: Identifiable, Codable {
    let id: Int64
    let tournamentId: Int64
    let userId: Int64
    let username: String
    let displayName: String
    let email: String
    let registrationDate: String
    let hasPaid: Bool
    let status: ParticipantStatus
    let placement: Int?
    let checkedInAt: String?
    let checkInCode: String?

    enum CodingKeys: String, CodingKey {
        case id
        case tournamentId
        case userId
        case user  // For nested user object
        case username
        case displayName
        case email
        case registrationDate
        case hasPaid
        case status
        case placement
        case checkedInAt
        case checkInCode
    }
    
    // Custom decoder to handle both nested user object and flat structure
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int64.self, forKey: .id)
        tournamentId = try container.decode(Int64.self, forKey: .tournamentId)
        userId = try container.decode(Int64.self, forKey: .userId)
        registrationDate = try container.decode(String.self, forKey: .registrationDate)
        hasPaid = try container.decode(Bool.self, forKey: .hasPaid)
        status = try container.decode(ParticipantStatus.self, forKey: .status)
        placement = try container.decodeIfPresent(Int.self, forKey: .placement)
        checkedInAt = try container.decodeIfPresent(String.self, forKey: .checkedInAt)
        checkInCode = try container.decodeIfPresent(String.self, forKey: .checkInCode)
        
        // Try to decode from nested user object first
        if let user = try? container.decode(User.self, forKey: .user) {
            username = user.username
            displayName = user.displayName
            email = user.email
        } else {
            // Fall back to flat structure
            username = try container.decode(String.self, forKey: .username)
            displayName = try container.decode(String.self, forKey: .displayName)
            email = try container.decode(String.self, forKey: .email)
        }
    }
    
    // Custom encoder to write in flat structure
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(tournamentId, forKey: .tournamentId)
        try container.encode(userId, forKey: .userId)
        try container.encode(username, forKey: .username)
        try container.encode(displayName, forKey: .displayName)
        try container.encode(email, forKey: .email)
        try container.encode(registrationDate, forKey: .registrationDate)
        try container.encode(hasPaid, forKey: .hasPaid)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(placement, forKey: .placement)
        try container.encodeIfPresent(checkedInAt, forKey: .checkedInAt)
        try container.encodeIfPresent(checkInCode, forKey: .checkInCode)
    }
    
    var isCheckedIn: Bool {
        return checkedInAt != nil
    }
    
    var checkedInDate: Date? {
        guard let checkedInAt = checkedInAt else { return nil }
        return ISO8601DateFormatter().date(from: checkedInAt)
    }
    
    var registrationDateFormatted: Date? {
        return ISO8601DateFormatter().date(from: registrationDate)
    }
    
    var placementBadge: String? {
        guard let p = placement else { return nil }
        switch p {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return nil
        }
    }
}