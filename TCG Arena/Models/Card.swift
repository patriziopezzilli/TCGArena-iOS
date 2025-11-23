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
    let name: String
    let rarity: Rarity
    let condition: CardCondition
    let imageURL: String?
    let isFoil: Bool
    let quantity: Int
    let ownerId: Int64
    let createdAt: Date
    let updatedAt: Date
    let tcgType: TCGType
    let set: String?
    let cardNumber: String?
    let expansion: Expansion?
    let marketPrice: Double?

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
    }

    enum CardCondition: String, CaseIterable, Codable {
        case mint = "Mint"
        case nearMint = "Near Mint"
        case lightlyPlayed = "Lightly Played"
        case moderatelyPlayed = "Moderately Played"
        case heavilyPlayed = "Heavily Played"
        case damaged = "Damaged"
    }
}

enum TCGType: String, CaseIterable, Codable {
    case pokemon = "Pokemon"
    case onePiece = "One Piece"
    case magic = "Magic: The Gathering"
    case yugioh = "Yu-Gi-Oh!"
    case digimon = "Digimon"
    
    var displayName: String {
        return self.rawValue
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
        }
    }
    
    var systemIcon: String {
        switch self {
        case .pokemon:
            return "bolt.fill"
        case .onePiece:
            return "sailboat.fill"
        case .magic:
            return "flame.fill"
        case .yugioh:
            return "eye.fill"
        case .digimon:
            return "shield.fill"
        }
    }
}