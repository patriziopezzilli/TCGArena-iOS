//
//  Card.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/5/25.
//

import Foundation
import SwiftUI

struct Card: Identifiable, Codable {
    let id: Int64?
    let templateId: Int64
    var name: String
    let rarity: Rarity
    var condition: CardCondition
    let imageURL: String?
    let isFoil: Bool
    let quantity: Int
    let ownerId: Int64
    let createdAt: Date
    let updatedAt: Date
    let tcgType: TCGType?
    let set: String?
    let cardNumber: String?
    let expansion: Expansion?
    let marketPrice: Double?
    let description: String?
    var deckNames: [String]? // Transient property for UI display

    // Grading fields
    var isGraded: Bool?
    var gradingCompany: GradeService?
    var grade: CardGrade?
    var certificateNumber: String?
    var gradingDate: Date?

    // Computed property per ottenere l'URL completo dell'immagine
    var fullImageURL: String? {
        guard let baseUrl = imageURL else { return nil }
        
        // Se l'URL contiene "tcgplayer", usalo direttamente (logica JustTCG)
        if baseUrl.lowercased().contains("tcgplayer") {
            return baseUrl
        }
        
        // Se l'URL è già completo (contiene "/high.webp"), restituiscilo così com'è
        if baseUrl.contains("/high.webp") {
            return baseUrl
        }
        // Altrimenti, aggiungi qualità "high" e formato "webp"
        return "\(baseUrl)/high.webp"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case templateId = "template_id"
        case name
        case rarity
        case condition
        case imageURL = "image_url"
        case isFoil = "is_foil"
        case quantity
        case ownerId = "owner_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case tcgType = "tcg_type"
        case set
        case cardNumber = "card_number"
        case expansion
        case marketPrice = "market_price"
        case description
        case isGraded = "isGraded"
        case gradingCompany = "grading_company"
        case grade
        case certificateNumber = "certificate_number"
        case gradingDate = "grading_date"
    }

// Designated initializer
    init(
        id: Int64?,
        templateId: Int64,
        name: String,
        rarity: Rarity,
        condition: CardCondition,
        imageURL: String?,
        isFoil: Bool,
        quantity: Int,
        ownerId: Int64,
        createdAt: Date,
        updatedAt: Date,
        tcgType: TCGType?,
        set: String?,
        cardNumber: String?,
        expansion: Expansion?,
        marketPrice: Double?,
        description: String?,
        isGraded: Bool? = nil,
        gradingCompany: GradeService? = nil,
        grade: CardGrade? = nil,
        certificateNumber: String? = nil,
        gradingDate: Date? = nil
    ) {
        self.id = id
        self.templateId = templateId
        self.name = name
        self.rarity = rarity
        self.condition = condition
        self.imageURL = imageURL
        self.isFoil = isFoil
        self.quantity = quantity
        self.ownerId = ownerId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.tcgType = tcgType
        self.set = set
        self.cardNumber = cardNumber
        self.expansion = expansion
        self.marketPrice = marketPrice
        self.description = description
        self.deckNames = nil
        self.isGraded = isGraded
        self.gradingCompany = gradingCompany
        self.grade = grade
        self.certificateNumber = certificateNumber
        self.gradingDate = gradingDate
    }

    // Convenience initializer from CardTemplate (for template cards)
    init(from template: CardTemplate) {
        self.init(
            id: nil,
            templateId: template.id,
            name: template.name,
            rarity: template.rarity,
            condition: .mint,
            imageURL: template.fullImageUrl,  // Usa l'URL completo invece di quello base
            isFoil: false,
            quantity: 1,
            ownerId: 0,
            createdAt: template.dateCreated,
            updatedAt: template.dateCreated,
            tcgType: template.tcgType,
            set: template.setCode,
            cardNumber: template.cardNumber,
            expansion: template.expansion,
            marketPrice: template.marketPrice,
            description: template.description
        )
    }
}

enum TCGType: String, CaseIterable, Codable, Identifiable {
    var id: String { rawValue }
    case pokemon = "POKEMON"
    case onePiece = "ONE_PIECE"
    case magic = "MAGIC"
    case yugioh = "YUGIOH"
    case digimon = "DIGIMON"
    case dragonBallSuper = "DRAGON_BALL_SUPER"
    case dragonBallFusion = "DRAGON_BALL_FUSION"
    case fleshAndBlood = "FLESH_AND_BLOOD"
    case lorcana = "LORCANA"
    
    var displayName: String {
        switch self {
        case .pokemon:
            return "Pokémon"
        case .onePiece:
            return "One Piece"
        case .magic:
            return "Magic: The Gathering"
        case .yugioh:
            return "Yu-Gi-Oh!"
        case .digimon:
            return "Digimon"
        case .dragonBallSuper:
            return "Dragon Ball Super"
        case .dragonBallFusion:
            return "Dragon Ball Fusion World"
        case .fleshAndBlood:
            return "Flesh and Blood"
        case .lorcana:
            return "Disney Lorcana"
        }
    }
    
    var themeColor: Color {
        switch self {
        case .pokemon:
            return Color.orange
        case .onePiece:
            return Color.red
        case .magic:
            return Color.blue
        case .yugioh:
            return Color.purple
        case .digimon:
            return Color.cyan
        case .dragonBallSuper:
            return Color.orange.opacity(0.8)
        case .dragonBallFusion:
            return Color.green
        case .fleshAndBlood:
            return Color.red.opacity(0.7)
        case .lorcana:
            return Color.indigo
        }
    }
    
    var systemIcon: String {
        switch self {
        case .pokemon:
            return "star.fill"
        case .onePiece:
            return "sailboat.fill"
        case .magic:
            return "sparkles"
        case .yugioh:
            return "eye.fill"
        case .digimon:
            return "shield.fill"
        case .dragonBallSuper:
            return "flame.fill"
        case .dragonBallFusion:
            return "flame.circle.fill"
        case .fleshAndBlood:
            return "theatermasks.fill"
        case .lorcana:
            return "wand.and.stars"
        }
    }
    
    /// Custom icon asset name if available
    var customIconName: String? {
        switch self {
        case .pokemon:
            return "pokemon_icon"
        case .onePiece:
            return "onepiece_icon"
        case .magic:
            return "magic_icon"
        case .yugioh:
            return "yugioh_icon"
        case .digimon:
            return "digimon_icon"
        case .dragonBallSuper, .dragonBallFusion:
            return "dragonball_icon"
        case .fleshAndBlood:
            return "fleshandblood_icon"
        case .lorcana:
            return "lorcana_icon"
        }
    }
    
    /// Whether this TCG has a custom icon
    var hasCustomIcon: Bool {
        customIconName != nil
    }
    
    // Hierarchy configuration (matches backend)
    var level1Label: String? {
        switch self {
        case .pokemon: return "Era"
        case .magic: return "Block"
        default: return nil
        }
    }
    
    var level2Label: String {
        switch self {
        case .digimon: return "Booster Set"
        default: return "Set"
        }
    }
    
    var hasRotation: Bool {
        switch self {
        case .pokemon, .magic, .lorcana: return true
        default: return false
        }
    }
    
    var usesBanlist: Bool {
        switch self {
        case .fleshAndBlood, .lorcana: return false
        default: return true
        }
    }
    
    var hasHierarchy: Bool {
        return level1Label != nil
    }
}

enum DeckType: String, Codable {
    case deck = "DECK"
    case lista = "LISTA"

    var displayName: String {
        switch self {
        case .deck: return "Deck"
        case .lista: return "Lista"
        }
    }
}