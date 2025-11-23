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

    enum CodingKeys: String, CodingKey {
        case id
        case tournamentId
        case userId
        case registrationDate
        case hasPaid
        case status
        case placement
    }
}

enum ParticipantStatus: String, Codable {
    case REGISTERED = "REGISTERED"
    case WAITING_LIST = "WAITING_LIST"
    case CANCELLED = "CANCELLED"
}