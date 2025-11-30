//
//  TCGCardView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/5/25.
//

import SwiftUI

struct TCGCardView: View {
    let card: Card
    let deckService: DeckService?
    let onTap: (() -> Void)?
    
    init(_ card: Card, deckService: DeckService? = nil, onTap: (() -> Void)? = nil) {
        self.card = card
        self.deckService = deckService
        self.onTap = onTap
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: TCGTheme.Spacing.sm) {
            // Header with TCG type badge
            HStack {
                TCGBadge(card.tcgType?.displayName ?? "Unknown", color: tcgColor)
                Spacer()
                RarityBadge(rarity: card.rarity)
            }
            
            // Card Name
            Text(card.name)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(TCGTheme.Colors.textPrimary)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
            
            // Set and Number
            HStack {
                Text(card.set ?? "Unknown")
                    .font(.system(size: 14))
                    .foregroundColor(TCGTheme.Colors.textSecondary)
                
                Spacer()
                
                Text("#\(card.cardNumber ?? "N/A")")
                    .font(.system(size: 14))
                    .foregroundColor(TCGTheme.Colors.textMuted)
            }
            
            // Condition bar
            ConditionIndicator(condition: card.condition)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
        )
    }
    
    private var tcgColor: Color {
        switch card.tcgType {
        case .pokemon: return Color(red: 1.0, green: 0.8, blue: 0.2) // Yellow
        case .onePiece: return Color(red: 0.2, green: 0.6, blue: 1.0) // Blue  
        case .magic: return Color(red: 0.8, green: 0.4, blue: 0.1) // Orange
        case .yugioh: return Color(red: 0.6, green: 0.2, blue: 0.8) // Purple
        case .digimon: return Color.cyan // Cyan
        case .none: return Color.gray
        }
    }
}

struct TCGBadge: View {
    let text: String
    let color: Color
    
    init(_ text: String, color: Color = TCGTheme.Colors.accent) {
        self.text = text
        self.color = color
    }
    
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color)
            .cornerRadius(6)
            .textCase(.uppercase)
            .tracking(0.3)
    }
}

struct RarityBadge: View {
    let rarity: Rarity
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<rarityStars, id: \.self) { _ in
                SwiftUI.Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundColor(rarityColor)
            }
        }
    }
    
    private var rarityStars: Int {
        switch rarity {
        case .common: return 1
        case .uncommon: return 2
        case .rare: return 3
        case .ultraRare, .holographic: return 4
        case .secretRare, .mythic: return 5
        case .promo: return 3
        case .legendary: return 6
        }
    }
    
    private var rarityColor: Color {
        switch rarity {
        case .common, .uncommon: return TCGTheme.Colors.textMuted
        case .rare: return TCGTheme.Colors.rareBorder
        case .ultraRare, .holographic: return TCGTheme.Colors.accent
        case .secretRare, .mythic: return TCGTheme.Colors.epicBorder
        case .promo: return TCGTheme.Colors.textMuted
        case .legendary: return TCGTheme.Colors.legendaryBorder
        }
    }
}

struct DeckBadge: View {
    let deckName: String
    
    var body: some View {
        Text(deckName)
            .font(.system(size: 12))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.blue)
            .cornerRadius(6)
            .lineLimit(1)
    }
}

struct ConditionIndicator: View {
    let condition: Card.CardCondition
    
    var body: some View {
        HStack(spacing: TCGTheme.Spacing.xs) {
            Text("Condition")
                .font(.system(size: 12))
                .foregroundColor(TCGTheme.Colors.textMuted)
            
            Spacer()
            
            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 1)
                        .frame(width: 6, height: 3)
                        .foregroundColor(index < conditionLevel ? conditionColor : TCGTheme.Colors.textMuted.opacity(0.3))
                }
            }
            
            Text(condition.rawValue)
                .font(.system(size: 12))
                .foregroundColor(conditionColor)
        }
    }
    
    private var conditionLevel: Int {
        switch condition {
        case .mint: return 5
        case .nearMint: return 4
        case .lightlyPlayed: return 3
        case .moderatelyPlayed: return 2
        case .heavilyPlayed: return 1
        case .damaged: return 1
        }
    }
    
    private var conditionColor: Color {
        switch condition {
        case .mint: return TCGTheme.Colors.success
        case .nearMint: return TCGTheme.Colors.success
        case .lightlyPlayed: return TCGTheme.Colors.warning
        case .moderatelyPlayed: return TCGTheme.Colors.warning
        case .heavilyPlayed: return TCGTheme.Colors.error
        case .damaged: return TCGTheme.Colors.error
        }
    }
}
