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
    let entryFee: Double
    let prizePool: Double
    let organizerId: Int64
    
    // Frontend-specific fields (computed or additional)
    var participants: [User] = []
    var tournamentParticipants: [TournamentParticipant] = []
    var location: TournamentLocation?
    var rules: String?
    
    var currentParticipants: Int {
        return participants.count
    }
    
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
        let name: String
        let address: String
        let city: String
        let country: String
        let latitude: Double
        let longitude: Double
        let phoneNumber: String?
        let website: String?
        
        var coordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case tcgType = "tcg_type"
        case type
        case status
        case startDate = "start_date"
        case endDate = "end_date"
        case maxParticipants = "max_participants"
        case entryFee = "entry_fee"
        case prizePool = "prize_pool"
        case organizerId = "organizer_id"
    }
    
    init(title: String, description: String?, tcgType: TCGType, type: TournamentType, status: TournamentStatus = .upcoming, startDate: String, endDate: String, maxParticipants: Int, entryFee: Double, prizePool: Double, organizerId: Int64, location: TournamentLocation? = nil, rules: String? = nil) {
        self.id = nil
        self.title = title
        self.description = description
        self.tcgType = tcgType
        self.type = type
        self.status = status
        self.startDate = startDate
        self.endDate = endDate
        self.maxParticipants = maxParticipants
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
        tournamentParticipants.filter { $0.status == .REGISTERED }.count
    }
    
    var waitingListCount: Int {
        tournamentParticipants.filter { $0.status == .WAITING_LIST }.count
    }
    
    var isFull: Bool {
        registeredParticipantsCount >= maxParticipants
    }
}