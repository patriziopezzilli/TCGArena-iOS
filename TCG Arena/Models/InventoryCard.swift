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
    let cardTemplateId: String  // Reference to the card template
    let shopId: String
    let condition: CardCondition
    let price: Double
    let quantity: Int
    let notes: String?
    let createdAt: Date
    let updatedAt: Date
    
    // Populated from CardTemplate (not stored, loaded via join/expansion)
    var cardTemplate: Card?  // The actual card data
    
    // Convenience accessors (delegate to cardTemplate)
    var name: String { cardTemplate?.name ?? "Unknown Card" }
    var setName: String? { cardTemplate?.set }
    var tcgType: TCGType { cardTemplate?.tcgType ?? .pokemon }
    var imageUrl: String? { cardTemplate?.imageURL }
    var marketPrice: Double? { cardTemplate?.marketPrice }
    
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
        cardTemplateId
    }
    
    enum CardCondition: String, Codable, CaseIterable {
        case nearMint = "NM"
        case slightlyPlayed = "SP"
        case moderatelyPlayed = "MP"
        case heavilyPlayed = "HP"
        case damaged = "DMG"
        
        var displayName: String {
            switch self {
            case .nearMint: return "Near Mint"
            case .slightlyPlayed: return "Slightly Played"
            case .moderatelyPlayed: return "Moderately Played"
            case .heavilyPlayed: return "Heavily Played"
            case .damaged: return "Damaged"
            }
        }
        
        var description: String {
            switch self {
            case .nearMint: return "Perfect or near-perfect condition"
            case .slightlyPlayed: return "Minor wear visible"
            case .moderatelyPlayed: return "Moderate wear, still playable"
            case .heavilyPlayed: return "Significant wear"
            case .damaged: return "Major damage or creases"
            }
        }
        
        var color: String {
            switch self {
            case .nearMint: return "green"
            case .slightlyPlayed: return "blue"
            case .moderatelyPlayed: return "yellow"
            case .heavilyPlayed: return "orange"
            case .damaged: return "red"
            }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case cardTemplateId = "card_template_id"
        case shopId = "shop_id"
        case condition, price, quantity, notes
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
    let cardTemplateId: String
    let shopId: String
    let condition: InventoryCard.CardCondition
    let price: Double
    let quantity: Int
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case cardTemplateId = "card_template_id"
        case shopId = "shop_id"
        case condition, price, quantity, notes
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

// MARK: - Filters
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
            params["only_available"] = "true"
        }
        if let searchQuery = searchQuery {
            params["search"] = searchQuery
        }
        
        return params
    }
}
