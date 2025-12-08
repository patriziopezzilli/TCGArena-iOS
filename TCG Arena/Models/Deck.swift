//
//  Deck.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/5/25.
//

import Foundation

struct Deck: Identifiable, Codable {
    let id: Int64?
    let name: String
    let tcgType: TCGType
    let deckType: DeckType
    var cards: [DeckCard]
    let ownerId: Int64
    let dateCreated: String
    let dateModified: String
    var isPublic: Bool
    let description: String?
    let tags: [String]
    
    struct DeckCard: Codable, Identifiable {
        let id: Int64?
        let cardId: Int64
        let quantity: Int
        let cardName: String
        let cardImageUrl: String?
        let condition: CardCondition?
        
        // Additional card info (optional, may not always be returned)
        let rarity: String?
        let setName: String?
        
        // Grading fields (optional, may not be returned by backend for deck cards)
        let isGraded: Bool?
        let gradingCompany: GradeService?
        let grade: CardGrade?
        let certificateNumber: String?
        
        var cardID: String { String(cardId) } // For backward compatibility
        
        enum CodingKeys: String, CodingKey {
            case id
            case cardId = "card_id"
            case quantity
            case cardName = "card_name"
            case cardImageUrl = "card_image_url"
            case condition
            case rarity
            case setName = "set_name"
            case isGraded = "isGraded"
            case gradingCompany = "gradeService"
            case grade
            case certificateNumber = "certificateNumber"
        }
    }
    
    var totalCards: Int {
        cards.reduce(0) { $0 + $1.quantity }
    }
    
    // Date strings are already formatted by the backend, so we can use them directly
    var formattedDateCreated: String {
        dateCreated
    }
    
    var formattedDateModified: String {
        dateModified
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case tcgType = "tcg_type"
        case deckType = "deck_type"
        case cards
        case ownerId = "owner_id"
        case dateCreated = "date_created"
        case dateModified = "date_modified"
        case isPublic = "is_public"
        case description
        case tags
    }
    
    init(name: String, tcgType: TCGType, ownerId: Int64, description: String? = nil, tags: [String] = []) {
        self.id = nil
        self.name = name
        self.tcgType = tcgType
        self.deckType = .lista // Default to lista type
        self.cards = []
        self.ownerId = ownerId
        self.dateCreated = ISO8601DateFormatter().string(from: Date())
        self.dateModified = ISO8601DateFormatter().string(from: Date())
        self.isPublic = false
        self.description = description
        self.tags = tags
    }
    
    // Constructor for updating existing deck
    init(id: Int64?, name: String, tcgType: TCGType, deckType: DeckType, cards: [DeckCard], ownerId: Int64, dateCreated: String, dateModified: String, isPublic: Bool, description: String?, tags: [String]) {
        self.id = id
        self.name = name
        self.tcgType = tcgType
        self.deckType = deckType
        self.cards = cards
        self.ownerId = ownerId
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.isPublic = isPublic
        self.description = description
        self.tags = tags
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(Int64.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        tcgType = try container.decode(TCGType.self, forKey: .tcgType)
        
        // Handle deckType - default to .lista if not present or null
        deckType = try container.decodeIfPresent(DeckType.self, forKey: .deckType) ?? .lista
        
        cards = try container.decode([DeckCard].self, forKey: .cards)
        ownerId = try container.decode(Int64.self, forKey: .ownerId)
        dateCreated = try container.decode(String.self, forKey: .dateCreated)
        dateModified = try container.decode(String.self, forKey: .dateModified)
        isPublic = try container.decode(Bool.self, forKey: .isPublic)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        tags = try container.decode([String].self, forKey: .tags)
    }
}