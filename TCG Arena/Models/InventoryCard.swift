//
//  InventoryCard.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/1/25.
//

import Foundation

/// Represents a card in a merchant's inventory
struct InventoryCard: Identifiable, Codable, Hashable {
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
    var setName: String? { cardTemplate?.setName }
    var tcgType: TCGType { cardTemplate?.tcgType ?? .pokemon }
    var imageUrl: String? { cardTemplate?.imageUrl }
    var marketPrice: Double? { cardTemplate?.marketPrice }
    
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
    var formattedPrice: String {
        return String(format: "€%.2f", price)
    }
    
    var conditionColor: String {
        switch condition {
        case .nearMint: return "green"
        case .slightlyPlayed: return "blue"
        case .moderatelyPlayed: return "yellow"
        case .heavilyPlayed: return "orange"
        case .damaged: return "red"
        }
    }
    
    // Helper initializer for creating new inventory items
    init(
        id: String = UUID().uuidString,
        game: TCGType,
        name: String,
        edition: String,
        rarity: String,
        country: String,
        condition: CardCondition,
        grading: String? = nil,
        price: Double? = nil,
        quantity: Int,
        merchantId: String,
        imageUrl: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.game = game
        self.name = name
        self.edition = edition
        self.rarity = rarity
        self.country = country
        self.condition = condition
        self.grading = grading
        self.price = price
        self.quantity = quantity
        self.merchantId = merchantId
        self.imageUrl = imageUrl
        self.createdAt = createdAt
        self.updatedAt = updatedAt
}

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

// MARK: - Filters
struct InventoryFilters {
    var tcgType: TCGType?
    var condition: InventoryCard.CardCondition?
    var minPrice: Double?
    var maxPrice: Double?
    var onlyAvailable: Bool = true
    
    init(
        tcgType: TCGType? = nil,
        condition: InventoryCard.CardCondition? = nil,
        minPrice: Double? = nil,
        maxPrice: Double? = nil,
        onlyAvailable: Bool = true
    ) {
        self.tcgType = tcgType
        self.condition = condition
        self.minPrice = minPrice
        self.maxPrice = maxPrice
        self.onlyAvailable = onlyAvailable
    }
}
        }
        
        return params
    }
}
