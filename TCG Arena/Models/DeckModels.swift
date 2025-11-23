import Foundation
import SwiftUI

// MARK: - Deck Models
// Note: Models for deck management with backend integration

struct LocalProDeckCard: Identifiable, Codable {
    let id = UUID()
    let cardTemplate: CardTemplate
    let quantity: Int
    let isMainboard: Bool // true = mainboard, false = sideboard
    
    init(cardTemplate: CardTemplate, quantity: Int, isMainboard: Bool = true) {
        self.cardTemplate = cardTemplate
        self.quantity = quantity
        self.isMainboard = isMainboard
    }
}

struct LocalProDeck: Identifiable, Codable {
    let id = UUID()
    let name: String
    let tcgType: TCGType
    let author: String
    let tournament: String
    let placement: String
    let date: Date
    let cards: [LocalProDeckCard]
    let sideboard: [LocalProDeckCard]
    let description: String
    let strategy: String
    let keyCards: [String] // Card names that are key to the strategy
    let stats: DeckStats
    let tags: [String] // Tags for categorization
    
    var totalMainboardCards: Int {
        return cards.reduce(0) { $0 + $1.quantity }
    }
    
    var totalSideboardCards: Int {
        return sideboard.reduce(0) { $0 + $1.quantity }
    }
    
    var totalCards: Int {
        return totalMainboardCards + totalSideboardCards
    }
    
    var manaCurve: [Int: Int] {
        // Per TCG con mana cost (Magic)
        var curve: [Int: Int] = [:]
        for card in cards {
            let cost = card.cardTemplate.manaCost ?? 0
            curve[cost, default: 0] += card.quantity
        }
        return curve
    }
}

struct DeckStats: Codable {
    let winRate: Double
    let playRate: Double
    let metaShare: Double
    let avgGameLength: Int // in minutes
    let difficultyLevel: DifficultyLevel
    let priceRange: PriceRange
    
    enum DifficultyLevel: String, Codable, CaseIterable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        case expert = "Expert"
        
        var color: Color {
            switch self {
            case .beginner: return .green
            case .intermediate: return .blue
            case .advanced: return .orange
            case .expert: return .red
            }
        }
    }
    
    enum PriceRange: String, Codable, CaseIterable {
        case budget = "Budget"
        case moderate = "Moderate"
        case expensive = "Expensive"
        case premium = "Premium"
        
        var description: String {
            switch self {
            case .budget: return "$0-50"
            case .moderate: return "$50-200"
            case .expensive: return "$200-500"
            case .premium: return "$500+"
            }
        }
        
        var color: Color {
            switch self {
            case .budget: return .green
            case .moderate: return .blue
            case .expensive: return .orange
            case .premium: return .red
            }
        }
    }
}