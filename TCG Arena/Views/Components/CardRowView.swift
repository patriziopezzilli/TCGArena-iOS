//
//  CardRowView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/5/25.
//

import SwiftUI

struct CardRowView: View {
    let card: Card
    let deckService: DeckService?
    
    init(card: Card, deckService: DeckService? = nil) {
        self.card = card
        self.deckService = deckService
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Card Thumbnail
            if let imageURL = card.fullImageURL, let url = URL(string: imageURL) {
                CachedAsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray5))
                            .frame(width: 50, height: 70)
                            .overlay(
                                ProgressView()
                                    .scaleEffect(0.5)
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 70)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    case .failure(_):
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray5))
                            .frame(width: 50, height: 70)
                            .overlay(
                                SwiftUI.Image(systemName: "photo")
                                    .font(.system(size: 20))
                                    .foregroundColor(.secondary)
                            )
                    @unknown default:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray5))
                            .frame(width: 50, height: 70)
                            .overlay(
                                SwiftUI.Image(systemName: "photo")
                                    .font(.system(size: 20))
                                    .foregroundColor(.secondary)
                            )
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(width: 50, height: 70)
                    .overlay(
                        SwiftUI.Image(systemName: "photo")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Header with TCG type badge
                HStack {
                    TCGBadge(card.tcgType?.displayName ?? "Unknown", color: tcgColor)
                    Spacer()
                    RarityBadge(rarity: card.rarity)
                }
                
                // Card Name
                Text(card.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(TCGTheme.Colors.textPrimary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                // Set and Number
                HStack {
                    Text(card.set ?? "Unknown")
                        .font(.system(size: 12))
                        .foregroundColor(TCGTheme.Colors.textSecondary)
                    
                    Spacer()
                    
                    Text("#\(card.cardNumber ?? "N/A")")
                        .font(.system(size: 12))
                        .foregroundColor(TCGTheme.Colors.textMuted)
                }
                
                // Condition bar
                ConditionIndicator(condition: card.condition)
            }
            
            Spacer()
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
        case .dragonBall: return Color.orange // Orange for Dragon Ball
        case .lorcana: return Color.indigo // Indigo for Lorcana
        case .none: return Color.gray
        }
    }
}
