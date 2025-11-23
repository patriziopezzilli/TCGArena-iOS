//
//  ProDeck.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/5/25.
//

import Foundation

struct ProDeck: Identifiable, Codable {
    let id: Int64
    let name: String
    let description: String
    let tcgType: TCGType
    let author: String
    let tournament: String
    let placement: String
    let createdAt: Date
    let updatedAt: Date
    let cards: [ProDeckCard]?
    
    var totalCards: Int {
        return cards?.reduce(0) { $0 + $1.quantity } ?? 0
    }
    
    var totalMainboardCards: Int {
        return cards?.filter { $0.section == "main" }.reduce(0) { $0 + $1.quantity } ?? 0
    }
    
    var keyCards: [String] {
        // Mock key cards - in real implementation, this would come from backend
        return []
    }
    
    var manaCurve: [Int: Int] {
        var curve: [Int: Int] = [:]
        cards?.forEach { card in
            if let manaCost = card.cardTemplate.manaCost {
                curve[manaCost, default: 0] += card.quantity
            }
        }
        return curve
    }
    
    var sideboard: [ProDeckCard] {
        return cards?.filter { $0.section == "sideboard" } ?? []
    }
}

struct ProDeckCard: Identifiable, Codable {
    let id: Int64
    let cardTemplate: CardTemplate
    let quantity: Int
    let section: String // "main" or "sideboard"
}