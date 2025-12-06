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
    let userId: Int
    let merchantId: Int
    let status: ReservationStatus
    let qrCode: String
    let expiresAt: Date
    let createdAt: Date
    let validatedAt: Date?
    let pickedUpAt: Date?
    let updatedAt: Date?
    
    // Flat data from API response
    let cardName: String?
    let cardRarity: String?
    let cardSet: String?
    let cardImageUrl: String?
    let shopName: String?
    let shopLocation: String?
    
    // Optional embedded data for UI (backward compatibility)
    var card: InventoryCard?
    var user: User?
    var shop: Shop?
    
    // Computed property per ottenere l'URL completo dell'immagine della carta
    var fullImageURL: String? {
        guard let baseUrl = cardImageUrl else { return nil }
        // Se l'URL è già completo (contiene "/high.webp"), restituiscilo così com'è
        if baseUrl.contains("/high.webp") {
            return baseUrl
        }
        // Altrimenti, aggiungi qualità "high" e formato "webp"
        return "\(baseUrl)/high.webp"
    }
    
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
        case updatedAt = "updated_at"
        case cardName = "card_name"
        case cardRarity = "card_rarity"
        case cardSet = "card_set"
        case cardImageUrl = "card_image_url"
        case shopName = "shop_name"
        case shopLocation = "shop_location"
    }
    
    // Custom date formatter for dates without timezone
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone(secondsFromGMT: 0) // UTC
        return formatter
    }()
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        cardId = try container.decode(String.self, forKey: .cardId)
        userId = try container.decode(Int.self, forKey: .userId)
        merchantId = try container.decode(Int.self, forKey: .merchantId)
        status = try container.decode(ReservationStatus.self, forKey: .status)
        qrCode = try container.decode(String.self, forKey: .qrCode)
        
        // Flat fields from API
        cardName = try container.decodeIfPresent(String.self, forKey: .cardName)
        cardRarity = try container.decodeIfPresent(String.self, forKey: .cardRarity)
        cardSet = try container.decodeIfPresent(String.self, forKey: .cardSet)
        cardImageUrl = try container.decodeIfPresent(String.self, forKey: .cardImageUrl)
        shopName = try container.decodeIfPresent(String.self, forKey: .shopName)
        shopLocation = try container.decodeIfPresent(String.self, forKey: .shopLocation)
        
        // Custom date decoding
        let expiresAtString = try container.decode(String.self, forKey: .expiresAt)
        expiresAt = Reservation.dateFormatter.date(from: expiresAtString) ?? Date()
        
        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        createdAt = Reservation.dateFormatter.date(from: createdAtString) ?? Date()
        
        // Optional dates
        if let validatedAtString = try container.decodeIfPresent(String.self, forKey: .validatedAt) {
            validatedAt = Reservation.dateFormatter.date(from: validatedAtString)
        } else {
            validatedAt = nil
        }
        
        if let pickedUpAtString = try container.decodeIfPresent(String.self, forKey: .pickedUpAt) {
            pickedUpAt = Reservation.dateFormatter.date(from: pickedUpAtString)
        } else {
            pickedUpAt = nil
        }
        
        if let updatedAtString = try container.decodeIfPresent(String.self, forKey: .updatedAt) {
            updatedAt = Reservation.dateFormatter.date(from: updatedAtString)
        } else {
            updatedAt = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(cardId, forKey: .cardId)
        try container.encode(userId, forKey: .userId)
        try container.encode(merchantId, forKey: .merchantId)
        try container.encode(status, forKey: .status)
        try container.encode(qrCode, forKey: .qrCode)
        
        try container.encodeIfPresent(cardName, forKey: .cardName)
        try container.encodeIfPresent(cardRarity, forKey: .cardRarity)
        try container.encodeIfPresent(cardSet, forKey: .cardSet)
        try container.encodeIfPresent(cardImageUrl, forKey: .cardImageUrl)
        try container.encodeIfPresent(shopName, forKey: .shopName)
        try container.encodeIfPresent(shopLocation, forKey: .shopLocation)
        
        // Custom date encoding
        try container.encode(Reservation.dateFormatter.string(from: expiresAt), forKey: .expiresAt)
        try container.encode(Reservation.dateFormatter.string(from: createdAt), forKey: .createdAt)
        
        if let validatedAt = validatedAt {
            try container.encode(Reservation.dateFormatter.string(from: validatedAt), forKey: .validatedAt)
        }
        if let pickedUpAt = pickedUpAt {
            try container.encode(Reservation.dateFormatter.string(from: pickedUpAt), forKey: .pickedUpAt)
        }
        if let updatedAt = updatedAt {
            try container.encode(Reservation.dateFormatter.string(from: updatedAt), forKey: .updatedAt)
        }
    }
    
    // Computed properties for backward compatibility
    var displayCardName: String {
        card?.name ?? cardName ?? "Unknown Card"
    }
    
    var displayShopName: String {
        shop?.name ?? shopName ?? "Unknown Shop"
    }
    
    var displayShopLocation: String {
        shop?.address ?? shopLocation ?? ""
    }
    
    var displayCardSet: String? {
        card?.setName ?? cardSet
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
