//
//  Tournament.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/5/25.
//

import Foundation
import MapKit

struct Tournament: Identifiable, Codable {
    let id: Int64?
    let title: String
    let description: String?
    let tcgType: TCGType
    let type: TournamentType
    let status: TournamentStatus
    let startDate: String
    let endDate: String
    let maxParticipants: Int
    let currentParticipants: Int?  // From backend - total registered participants count
    let entryFee: Double
    let prizePool: String
    let organizerId: Int64
    
    // Frontend-specific fields (computed or additional)
    var participants: [User] = []
    var tournamentParticipants: [TournamentParticipantWithUser] = []
    var location: TournamentLocation?
    var rules: String?
    var winnerId: Int64? // Winner's user ID
    
    enum TournamentType: String, CaseIterable, Codable {
        case casual = "CASUAL"
        case competitive = "COMPETITIVE"
        case championship = "CHAMPIONSHIP"
    }
    
    enum TournamentStatus: String, CaseIterable, Codable {
        case upcoming = "UPCOMING"
        case registrationOpen = "REGISTRATION_OPEN"
        case registrationClosed = "REGISTRATION_CLOSED"
        case inProgress = "IN_PROGRESS"
        case completed = "COMPLETED"
        case cancelled = "CANCELLED"
    }
    
    struct TournamentLocation: Codable {
        let venueName: String
        let address: String
        let city: String
        let country: String
        let latitude: Double?
        let longitude: Double?
        
        var coordinate: CLLocationCoordinate2D? {
            guard let lat = latitude, let lon = longitude else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        
        var displayName: String {
            "\(venueName), \(city)"
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case tcgType
        case type
        case status
        case startDate
        case endDate
        case maxParticipants
        case currentParticipants
        case entryFee
        case prizePool
        case organizerId
        case location
        case winnerId
        case tournamentParticipants = "participants"
    }
    
    init(title: String, description: String?, tcgType: TCGType, type: TournamentType, status: TournamentStatus = .upcoming, startDate: String, endDate: String, maxParticipants: Int, currentParticipants: Int? = nil, entryFee: Double, prizePool: String, organizerId: Int64, location: TournamentLocation? = nil, rules: String? = nil) {
        self.id = nil
        self.title = title
        self.description = description
        self.tcgType = tcgType
        self.type = type
        self.status = status
        self.startDate = startDate
        self.endDate = endDate
        self.maxParticipants = maxParticipants
        self.currentParticipants = currentParticipants
        self.entryFee = entryFee
        self.prizePool = prizePool
        self.organizerId = organizerId
        self.location = location
        self.rules = rules
    }
    
    // Computed properties for date display (dates are already formatted as strings by backend)
    var formattedStartDate: String {
        startDate
    }
    
    var formattedEndDate: String {
        endDate
    }
    
    var registeredParticipantsCount: Int {
        return currentParticipants ?? tournamentParticipants.filter { $0.status == .REGISTERED }.count
    }
    
    var waitingListCount: Int {
        tournamentParticipants.filter { $0.status == .WAITING_LIST }.count
    }
    
    var isFull: Bool {
        // Use registeredParticipantsCount which considers both backend currentParticipants
        // and local tournamentParticipants array
        return registeredParticipantsCount >= maxParticipants
    }
}