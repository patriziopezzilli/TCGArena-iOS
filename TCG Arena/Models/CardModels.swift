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
    let tcgType: TCGType?  // Temporaneamente opzionale per debug
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
        case tcgType
        case setCode
        case expansion
        case rarity
        case cardNumber
        case description
        case imageUrl
        case marketPrice
        case manaCost
        case dateCreated
    }
    
    // Computed property per ottenere l'URL completo dell'immagine
    var fullImageUrl: String? {
        guard let baseUrl = imageUrl else { return nil }
        
        // Se l'URL contiene "tcgplayer", usalo direttamente (logica JustTCG)
        if baseUrl.lowercased().contains("tcgplayer") {
            return baseUrl
        }
        
        // Altrimenti aggiungi qualità "high" e formato "webp" come raccomandato
        return "\(baseUrl)/high.webp"
    }
    
    // Versione con parametri personalizzabili
    func imageUrl(quality: String = "high", format: String = "webp") -> String? {
        guard let baseUrl = imageUrl else { return nil }
        
        // Se l'URL contiene "tcgplayer", usalo direttamente
        if baseUrl.lowercased().contains("tcgplayer") {
            return baseUrl
        }
        
        return "\(baseUrl)/\(quality).\(format)"
    }
    
    // Public initializer for creating mock instances
    init(
        id: Int64,
        name: String,
        tcgType: TCGType?,  // Aggiornato per accettare opzionale
        setCode: String,
        expansion: Expansion?,
        rarity: Rarity,
        cardNumber: String,
        description: String?,
        imageUrl: String?,
        marketPrice: Double?,
        manaCost: Int?,
        dateCreated: Date
    ) {
        self.id = id
        self.name = name
        self.tcgType = tcgType
        self.setCode = setCode
        self.expansion = expansion
        self.rarity = rarity
        self.cardNumber = cardNumber
        self.description = description
        self.imageUrl = imageUrl
        self.marketPrice = marketPrice
        self.manaCost = manaCost
        self.dateCreated = dateCreated
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int64.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        tcgType = try container.decodeIfPresent(TCGType.self, forKey: .tcgType)
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
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            formatter.timeZone = TimeZone(secondsFromGMT: 0) // UTC
            dateCreated = formatter.date(from: dateString) ?? Date()
        } else {
            dateCreated = Date()
        }
    }
    
    // Helper method to convert CardTemplate to Card for discover flow
    func toCard() -> Card {
        return Card(
            id: nil,  // No ID for discovered cards
            templateId: self.id,
            name: self.name,
            rarity: self.rarity,
            condition: .nearMint,  // Default condition for discovered cards
            imageURL: self.imageUrl,
            isFoil: false,
            quantity: 1,
            ownerId: 0,  // Default owner ID for discovered cards
            createdAt: self.dateCreated,
            updatedAt: self.dateCreated,
            tcgType: self.tcgType ?? .pokemon,  // Default to pokemon if not set
            set: self.setCode,
            cardNumber: self.cardNumber,
            expansion: self.expansion,
            marketPrice: self.marketPrice,
            description: self.description
        )
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
    case superRare = "SUPER_RARE"
    case secretRare = "SECRET_RARE"
    case holographic = "HOLOGRAPHIC"
    case promo = "PROMO"
    case mythic = "MYTHIC"
    case legendary = "LEGENDARY"
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let stringValue = try container.decode(String.self)
        switch stringValue {
        case "COMMON": self = .common
        case "UNCOMMON": self = .uncommon
        case "RARE": self = .rare
        case "ULTRA_RARE": self = .ultraRare
        case "SUPER_RARE": self = .superRare
        case "SECRET_RARE", "SECRET": self = .secretRare
        case "HOLOGRAPHIC": self = .holographic
        case "PROMO": self = .promo
        case "MYTHIC": self = .mythic
        case "LEGENDARY": self = .legendary
        default:
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid rarity value: \(stringValue)")
        }
    }
    
    var displayName: String {
        switch self {
        case .common: return "Common"
        case .uncommon: return "Uncommon"
        case .rare: return "Rare"
        case .ultraRare: return "Ultra Rare"
        case .superRare: return "Super Rare"
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
        case .superRare:
            return Color.red.opacity(0.8)
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
        case .superRare: return "SPR"
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
    
    var displayName: String {
        switch self {
        case .psa: return "PSA"
        case .bgs: return "BGS"
        case .cgc: return "CGC"
        case .beckett: return "Beckett"
        }
    }
}

// Enum per CardGrade
enum CardGrade: String, Codable, CaseIterable {
    case grade10 = "10"
    case grade9_5 = "9.5"
    case grade9 = "9"
    case grade8_5 = "8.5"
    case grade8 = "8"
    case grade7_5 = "7.5"
    case grade7 = "7"
    case grade6_5 = "6.5"
    case grade6 = "6"
    case grade5_5 = "5.5"
    case grade5 = "5"
    case grade4_5 = "4.5"
    case grade4 = "4"
    case grade3_5 = "3.5"
    case grade3 = "3"
    case grade2_5 = "2.5"
    case grade2 = "2"
    case grade1_5 = "1.5"
    case grade1 = "1"
    
    var displayName: String {
        return rawValue
    }
    
    var numericValue: Double {
        switch self {
        case .grade10: return 10.0
        case .grade9_5: return 9.5
        case .grade9: return 9.0
        case .grade8_5: return 8.5
        case .grade8: return 8.0
        case .grade7_5: return 7.5
        case .grade7: return 7.0
        case .grade6_5: return 6.5
        case .grade6: return 6.0
        case .grade5_5: return 5.5
        case .grade5: return 5.0
        case .grade4_5: return 4.5
        case .grade4: return 4.0
        case .grade3_5: return 3.5
        case .grade3: return 3.0
        case .grade2_5: return 2.5
        case .grade2: return 2.0
        case .grade1_5: return 1.5
        case .grade1: return 1.0
        }
    }
}

// Modello per risposta API paginata
struct PagedResponse<T: Codable>: Codable {
    let content: [T]
    let pageable: PageableInfo
    let totalPages: Int
    let totalElements: Int
    let last: Bool
    let numberOfElements: Int
    let first: Bool
    let size: Int
    let number: Int
    let sort: SortInfo
    let empty: Bool
    
    enum CodingKeys: String, CodingKey {
        case content, pageable, totalPages, totalElements, last, numberOfElements, first, size, number, sort, empty
    }
}

struct PageableInfo: Codable {
    let pageNumber: Int
    let pageSize: Int
    let sort: SortInfo
    let offset: Int
    let paged: Bool
    let unpaged: Bool
}

struct SortInfo: Codable {
    let sorted: Bool
    let unsorted: Bool
    let empty: Bool
}