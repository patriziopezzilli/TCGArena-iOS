//
//  InventoryCard.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/1/25.
//

import Foundation

/// Represents a card in a merchant's inventory
struct InventoryCard: Identifiable, Codable {
    let id: String
    let cardTemplateId: Int  // Reference to the card template
    let shopId: Int
    let condition: CardCondition
    let price: Double
    let quantity: Int
    let notes: String?
    let nationality: String?
    let createdAt: Date
    let updatedAt: Date
    
    // Populated from CardTemplate (not stored, loaded via join/expansion)
    var cardTemplate: CardTemplate?  // The actual card data
    
    // Convenience accessors (delegate to cardTemplate)
    var name: String { cardTemplate?.name ?? "Unknown Card" }
    var setName: String? { cardTemplate?.setCode }
    var tcgType: TCGType { cardTemplate?.tcgType ?? .pokemon }
    var imageUrl: String? { cardTemplate?.imageUrl }
    var marketPrice: Double? { cardTemplate?.marketPrice }
    
    // Computed property per ottenere l'URL completo dell'immagine
    // Usa fullImageUrl di CardTemplate che include già la logica corretta
    var fullImageURL: String? {
        return cardTemplate?.fullImageUrl
    }
    
    var formattedPrice: String {
        String(format: "€%.2f", price)
    }
    
    var conditionColor: String {
        condition.color
    }
    
    var isAvailable: Bool {
        quantity > 0
    }
    
    var cardId: String {
        String(cardTemplateId)
    }
    
    var nationalityDisplayName: String? {
        guard let nationality = nationality else { return nil }
        switch nationality {
        case "JPN": return "Japanese"
        case "ITA": return "Italian"
        case "EN": return "English"
        case "COR": return "Korean"
        case "FRA": return "French"
        case "GER": return "German"
        case "SPA": return "Spanish"
        case "POR": return "Portuguese"
        case "CHI": return "Chinese"
        case "RUS": return "Russian"
        default: return nationality
        }
    }
    
    enum CardCondition: String, Codable, CaseIterable {
        case mint = "MINT"
        case nearMint = "NEAR_MINT"
        case excellent = "EXCELLENT"
        case good = "GOOD"
        case lightPlayed = "LIGHT_PLAYED"
        case played = "PLAYED"
        case poor = "POOR"
        
        var displayName: String {
            switch self {
            case .mint: return "Mint"
            case .nearMint: return "Near Mint"
            case .excellent: return "Excellent"
            case .good: return "Good"
            case .lightPlayed: return "Light Played"
            case .played: return "Played"
            case .poor: return "Poor"
            }
        }
        
        var shortName: String {
            switch self {
            case .mint: return "M"
            case .nearMint: return "NM"
            case .excellent: return "EX"
            case .good: return "GD"
            case .lightPlayed: return "LP"
            case .played: return "PL"
            case .poor: return "P"
            }
        }
        
        var description: String {
            switch self {
            case .mint: return "Perfect condition"
            case .nearMint: return "Near perfect condition"
            case .excellent: return "Excellent condition"
            case .good: return "Good condition"
            case .lightPlayed: return "Lightly played"
            case .played: return "Played"
            case .poor: return "Poor condition"
            }
        }
        
        var color: String {
            switch self {
            case .mint, .nearMint: return "green"
            case .excellent, .good: return "blue"
            case .lightPlayed: return "yellow"
            case .played: return "orange"
            case .poor: return "red"
            }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case cardTemplateId = "card_template_id"
        case shopId = "shop_id"
        case condition, price, quantity, notes, nationality
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case cardTemplate = "card_template"
    }
    
    // Manual Hashable/Equatable implementation (cardTemplate is not Hashable)
    static func == (lhs: InventoryCard, rhs: InventoryCard) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Hashable/Equatable conformance
extension InventoryCard: Hashable, Equatable {}

// MARK: - Create/Update DTOs
struct CreateInventoryCardRequest: Codable {
    let cardTemplateId: Int
    let shopId: Int
    let condition: InventoryCard.CardCondition
    let price: Double
    let quantity: Int
    let notes: String?
    let nationality: String?
    
    enum CodingKeys: String, CodingKey {
        case cardTemplateId = "card_template_id"
        case shopId = "shop_id"
        case condition, price, quantity, notes, nationality
    }
}

struct UpdateInventoryCardRequest: Codable {
    let condition: InventoryCard.CardCondition?
    let price: Double?
    let quantity: Int?
    let notes: String?
}

struct InventoryQuantityUpdate: Codable {
    let delta: Int
}

// MARK: - API Response DTOs
struct InventoryResponse: Codable {
    let inventory: [InventoryCard]
    let total: Int
    let page: Int
    let pageSize: Int
}
struct InventoryFilters {
    var tcgType: TCGType?
    var condition: InventoryCard.CardCondition?
    var minPrice: Double?
    var maxPrice: Double?
    var onlyAvailable: Bool = true
    var searchQuery: String?
    
    init(
        tcgType: TCGType? = nil,
        condition: InventoryCard.CardCondition? = nil,
        minPrice: Double? = nil,
        maxPrice: Double? = nil,
        onlyAvailable: Bool = true,
        searchQuery: String? = nil
    ) {
        self.tcgType = tcgType
        self.condition = condition
        self.minPrice = minPrice
        self.maxPrice = maxPrice
        self.onlyAvailable = onlyAvailable
        self.searchQuery = searchQuery
    }
    
    var queryParameters: [String: String] {
        var params: [String: String] = [:]
        
        if let tcgType = tcgType {
            params["tcg_type"] = tcgType.rawValue
        }
        if let condition = condition {
            params["condition"] = condition.rawValue
        }
        if let minPrice = minPrice {
            params["min_price"] = String(minPrice)
        }
        if let maxPrice = maxPrice {
            params["max_price"] = String(maxPrice)
        }
        if onlyAvailable {
            // TODO: Backend doesn't support only_available filter yet
            // params["only_available"] = "true"
        }
        if let searchQuery = searchQuery {
            params["search"] = searchQuery
        }
        
        return params
    }
}
