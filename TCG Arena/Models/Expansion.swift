//
//  Expansion.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/10/25.
//

import Foundation

struct Expansion: Identifiable, Codable {
    let id: Int64
    let title: String
    let tcgType: TCGType
    let imageUrl: String?
    let sets: [TCGSet]
    
    enum CodingKeys: String, CodingKey {
        case id, title, tcgType
        case imageUrl = "imageUrl"
        case sets
    }
    
    // Computed properties for display
    var formattedReleaseDate: String {
        sets.first?.formattedReleaseDate ?? "Unknown"
    }
    
    var cardCount: Int {
        sets.reduce(0) { $0 + $1.cardCount }
    }
}

// MARK: - Mock Data
