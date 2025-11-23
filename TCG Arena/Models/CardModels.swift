//
//  CardModels.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/22/25.
//

import Foundation
import SwiftUI

// Modello per CardTemplate (dal backend)
struct CardTemplate: Identifiable, Codable {
    let id: Int64
    let name: String
    let tcgType: TCGType
    let setCode: String
    let expansion: Expansion?
    let rarity: Rarity
    let cardNumber: String
    let description: String?
    let imageUrl: String?
    let marketPrice: Double?
    let manaCost: Int?
    let dateCreated: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case tcgType = "tcg_type"
        case setCode = "set_code"
        case expansion
        case rarity
        case cardNumber = "card_number"
        case description
        case imageUrl = "image_url"
        case marketPrice = "market_price"
        case manaCost = "mana_cost"
        case dateCreated = "date_created"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int64.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        tcgType = try container.decode(TCGType.self, forKey: .tcgType)
        setCode = try container.decode(String.self, forKey: .setCode)
        expansion = try container.decodeIfPresent(Expansion.self, forKey: .expansion)
        rarity = try container.decode(Rarity.self, forKey: .rarity)
        cardNumber = try container.decode(String.self, forKey: .cardNumber)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        marketPrice = try container.decodeIfPresent(Double.self, forKey: .marketPrice)
        manaCost = try container.decodeIfPresent(Int.self, forKey: .manaCost)
        
        // Gestisci conversione data
        if let dateString = try? container.decode(String.self, forKey: .dateCreated) {
            let formatter = ISO8601DateFormatter()
            dateCreated = formatter.date(from: dateString) ?? Date()
        } else {
            dateCreated = Date()
        }
    }
}

// Modello per UserCard (dal backend)
struct UserCard: Identifiable, Codable {
    let id: Int64
    let cardTemplate: CardTemplate
    let owner: User
    let condition: CardCondition
    let isGraded: Bool
    let gradeService: GradeService?
    let gradeScore: Int?
    let purchasePrice: Double?
    let dateAcquired: Date?
    let dateAdded: Date
    let deckId: Int64?
    
    enum CodingKeys: String, CodingKey {
        case id
        case cardTemplate = "card_template"
        case owner
        case condition
        case isGraded = "is_graded"
        case gradeService = "grade_service"
        case gradeScore = "grade_score"
        case purchasePrice = "purchase_price"
        case dateAcquired = "date_acquired"
        case dateAdded = "date_added"
        case deckId = "deck_id"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int64.self, forKey: .id)
        cardTemplate = try container.decode(CardTemplate.self, forKey: .cardTemplate)
        owner = try container.decode(User.self, forKey: .owner)
        condition = try container.decode(CardCondition.self, forKey: .condition)
        isGraded = try container.decode(Bool.self, forKey: .isGraded)
        gradeService = try container.decodeIfPresent(GradeService.self, forKey: .gradeService)
        gradeScore = try container.decodeIfPresent(Int.self, forKey: .gradeScore)
        purchasePrice = try container.decodeIfPresent(Double.self, forKey: .purchasePrice)
        deckId = try container.decodeIfPresent(Int64.self, forKey: .deckId)
        
        // Gestisci conversione date
        if let dateString = try? container.decode(String.self, forKey: .dateAcquired) {
            let formatter = ISO8601DateFormatter()
            dateAcquired = formatter.date(from: dateString)
        } else {
            dateAcquired = nil
        }
        
        if let dateString = try? container.decode(String.self, forKey: .dateAdded) {
            let formatter = ISO8601DateFormatter()
            dateAdded = formatter.date(from: dateString) ?? Date()
        } else {
            dateAdded = Date()
        }
    }
}

// Enum per Rarity
enum Rarity: String, Codable, CaseIterable {
    case common = "COMMON"
    case uncommon = "UNCOMMON"
    case rare = "RARE"
    case ultraRare = "ULTRA_RARE"
    case secretRare = "SECRET_RARE"
    case holographic = "HOLOGRAPHIC"
    case promo = "PROMO"
    case mythic = "MYTHIC"
    case legendary = "LEGENDARY"
    
    var displayName: String {
        switch self {
        case .common: return "Common"
        case .uncommon: return "Uncommon"
        case .rare: return "Rare"
        case .ultraRare: return "Ultra Rare"
        case .secretRare: return "Secret Rare"
        case .holographic: return "Holographic"
        case .promo: return "Promo"
        case .mythic: return "Mythic"
        case .legendary: return "Legendary"
        }
    }

    var color: Color {
        switch self {
        case .common:
            return Color.gray
        case .uncommon:
            return Color.green
        case .rare:
            return Color.blue
        case .ultraRare:
            return Color.purple
        case .secretRare:
            return Color.red
        case .holographic:
            return Color.cyan
        case .promo:
            return Color.orange
        case .mythic:
            return Color.yellow
        case .legendary:
            return Color.pink
        }
    }

    var shortName: String {
        switch self {
        case .common: return "C"
        case .uncommon: return "U"
        case .rare: return "R"
        case .ultraRare: return "UR"
        case .secretRare: return "SR"
        case .holographic: return "H"
        case .promo: return "P"
        case .mythic: return "M"
        case .legendary: return "L"
        }
    }
}

// Enum per CardCondition
enum CardCondition: String, Codable, CaseIterable {
    case mint = "MINT"
    case nearMint = "NEAR_MINT"
    case lightlyPlayed = "LIGHTLY_PLAYED"
    case moderatelyPlayed = "MODERATELY_PLAYED"
    case heavilyPlayed = "HEAVILY_PLAYED"
    case damaged = "DAMAGED"
    
    var displayName: String {
        switch self {
        case .mint: return "Mint"
        case .nearMint: return "Near Mint"
        case .lightlyPlayed: return "Lightly Played"
        case .moderatelyPlayed: return "Moderately Played"
        case .heavilyPlayed: return "Heavily Played"
        case .damaged: return "Damaged"
        }
    }
}

// Enum per GradeService
enum GradeService: String, Codable, CaseIterable {
    case psa = "PSA"
    case bgs = "BGS"
    case cgc = "CGC"
    case beckett = "BECKETT"
}