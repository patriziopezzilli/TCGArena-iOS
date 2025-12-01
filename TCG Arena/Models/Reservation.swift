//
//  Reservation.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/1/25.
//

import Foundation

/// Represents a card reservation made by a user
struct Reservation: Identifiable, Codable {
    let id: String
    let cardId: String
    let userId: String
    let merchantId: String
    let status: ReservationStatus
    let qrCode: String
    let expiresAt: Date
    let createdAt: Date
    let validatedAt: Date?
    let pickedUpAt: Date?
    
    // Optional embedded data for UI
    var card: InventoryCard?
    var user: User?
    var shop: Shop?
    
    enum ReservationStatus: String, Codable, CaseIterable {
        case pending = "PENDING"
        case validated = "VALIDATED"
        case pickedUp = "PICKED_UP"
        case expired = "EXPIRED"
        case cancelled = "CANCELLED"
        
        var displayName: String {
            switch self {
            case .pending: return "Pending"
            case .validated: return "Validated"
            case .pickedUp: return "Picked Up"
            case .expired: return "Expired"
            case .cancelled: return "Cancelled"
            }
        }
        
        var color: String {
            switch self {
            case .pending: return "orange"
            case .validated: return "blue"
            case .pickedUp: return "green"
            case .expired: return "gray"
            case .cancelled: return "red"
            }
        }
        
        var icon: String {
            switch self {
            case .pending: return "clock.fill"
            case .validated: return "checkmark.circle.fill"
            case .pickedUp: return "bag.fill"
            case .expired: return "xmark.circle.fill"
            case .cancelled: return "trash.fill"
            }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case cardId = "card_id"
        case userId = "user_id"
        case merchantId = "merchant_id"
        case status
        case qrCode = "qr_code"
        case expiresAt = "expires_at"
        case createdAt = "created_at"
        case validatedAt = "validated_at"
        case pickedUpAt = "picked_up_at"
    }
    
    // Computed properties
    var isActive: Bool {
        status == .pending || status == .validated
    }
    
    var isExpired: Bool {
        Date() > expiresAt && status == .pending
    }
    
    var canBeCancelled: Bool {
        status == .pending || status == .validated
    }
    
    var canBeValidated: Bool {
        status == .pending && !isExpired
    }
    
    var canBePickedUp: Bool {
        status == .validated && !isExpired
    }
    
    var timeRemaining: TimeInterval {
        max(0, expiresAt.timeIntervalSinceNow)
    }
    
    var formattedTimeRemaining: String {
        let hours = Int(timeRemaining) / 3600
        let minutes = (Int(timeRemaining) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m remaining"
        } else if minutes > 0 {
            return "\(minutes)m remaining"
        } else if timeRemaining > 0 {
            return "Less than 1m remaining"
        } else {
            return "Expired"
        }
    }
    
    // Manual Hashable/Equatable implementation
    static func == (lhs: Reservation, rhs: Reservation) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Hashable/Equatable conformance
extension Reservation: Hashable, Equatable {}

// MARK: - Request DTOs
struct CreateReservationRequest: Codable {
    let cardId: String
    let quantity: Int // how many copies of the card to reserve (optional, default 1)
    
    enum CodingKeys: String, CodingKey {
        case cardId = "card_id"
        case quantity
    }
}

struct ValidateReservationRequest: Codable {
    let qrCode: String
    
    enum CodingKeys: String, CodingKey {
        case qrCode = "qr_code"
    }
}

struct ReservationResponse: Codable {
    let reservation: Reservation
    let message: String?
}

// MARK: - List Response
struct ReservationListResponse: Codable {
    let reservations: [Reservation]
    let total: Int
}
