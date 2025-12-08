//
//  ProductType.swift
//  TCG Arena
//
//  Classification of TCG products/sets across all games.
//

import Foundation

/// Classification of TCG products/sets across all games.
/// Used to categorize expansions and sets for filtering and display.
enum ProductType: String, CaseIterable, Codable {
    // Main product types
    case boosterSet = "BOOSTER_SET"              // Main booster packs (e.g., XY Flashfire, OP-01)
    case starterDeck = "STARTER_DECK"            // Pre-built starter decks (e.g., ST-01)
    case structureDeck = "STRUCTURE_DECK"        // Pre-built themed decks (Yu-Gi-Oh!)
    
    // Special products
    case specialSet = "SPECIAL_SET"              // Sub-sets (Shiny Vault, Trainer Gallery)
    case premiumPack = "PREMIUM_PACK"            // Premium/gift products
    case promo = "PROMO"                         // Promo cards
    case tin = "TIN"                             // Collector tins
    case boxSet = "BOX_SET"                      // Gift/box sets
    case themeBooster = "THEME_BOOSTER"          // Theme boosters (Digimon)
    
    // Magic-specific
    case mastersSet = "MASTERS_SET"              // Masters reprint sets
    case commanderSet = "COMMANDER_SET"          // Commander pre-cons
    case supplemental = "SUPPLEMENTAL"           // Supplemental products
    
    // Flesh and Blood specific
    case standaloneSet = "STANDALONE_SET"
    
    // Unknown/default
    case other = "OTHER"
    
    var displayName: String {
        switch self {
        case .boosterSet: return "Booster Set"
        case .starterDeck: return "Starter Deck"
        case .structureDeck: return "Structure Deck"
        case .specialSet: return "Special Set"
        case .premiumPack: return "Premium Pack"
        case .promo: return "Promo"
        case .tin: return "Tin"
        case .boxSet: return "Box Set"
        case .themeBooster: return "Theme Booster"
        case .mastersSet: return "Masters Set"
        case .commanderSet: return "Commander"
        case .supplemental: return "Supplemental"
        case .standaloneSet: return "Standalone Set"
        case .other: return "Other"
        }
    }
}
