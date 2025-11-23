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
    var cards: [DeckCard]
    let ownerId: Int64
    var dateCreated: Date
    var dateModified: Date
    var isPublic: Bool
    let description: String?
    let tags: [String]
    
    struct DeckCard: Codable, Identifiable {
        let id: Int64?
        let cardId: Int64
        let quantity: Int
        let cardName: String
        let cardImageUrl: String?
        
        var cardID: String { String(cardId) } // For backward compatibility
        
        enum CodingKeys: String, CodingKey {
            case id
            case cardId = "card_id"
            case quantity
            case cardName = "card_name"
            case cardImageUrl = "card_image_url"
        }
    }
    
    var totalCards: Int {
        cards.reduce(0) { $0 + $1.quantity }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case tcgType = "tcg_type"
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
        self.cards = []
        self.ownerId = ownerId
        self.dateCreated = Date()
        self.dateModified = Date()
        self.isPublic = false
        self.description = description
        self.tags = tags
    }
}