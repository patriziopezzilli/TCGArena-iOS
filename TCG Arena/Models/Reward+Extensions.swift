//
//  Reward+Extensions.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/06/25.
//

import SwiftUI

extension Reward {
    var category: RewardsView.RewardCategory {
        // Check for exclusive first
        if description.lowercased().contains("exclusive") {
            return .exclusive
        }
        
        switch self.type {
        case .physical: return .physical
        case .digital: return .digital
        }
    }

    var genre: RewardGenre {
        // Infer genre from name or partner
        let lowerName = name.lowercased()
        if lowerName.contains("pokemon") { return .pokemon }
        if lowerName.contains("magic") { return .magic }
        if lowerName.contains("one piece") { return .onePiece }
        if lowerName.contains("yugioh") { return .yugioh }
        if lowerName.contains("digimon") { return .digimon }
        if lowerName.contains("tournament") { return .tournament }
        return .physical
    }
    
    var imageIcon: String {
        switch genre {
        case .pokemon: return "bolt.fill"
        case .magic: return "sparkles"
        case .physical: return "rectangle.stack"
        case .exclusive: return "crown.fill"
        case .tournament: return "trophy.fill"
        case .onePiece: return "sailboat.fill"
        default: return "gift.fill"
        }
    }
}

enum RewardGenre {
    case pokemon, magic, onePiece, yugioh, digimon, physical, exclusive, tournament

    var color: Color {
        switch self {
        case .pokemon: return Color(red: 1.0, green: 0.7, blue: 0.0)
        case .magic: return Color(red: 1.0, green: 0.5, blue: 0.0)
        case .onePiece: return Color(red: 0.0, green: 0.7, blue: 1.0)
        case .yugioh: return Color(red: 0.56, green: 0.60, blue: 0.63)
        case .digimon: return Color.cyan
        case .physical: return .brown
        case .exclusive: return Color(red: 0.56, green: 0.60, blue: 0.63)
        case .tournament: return .green
        }
    }
}
