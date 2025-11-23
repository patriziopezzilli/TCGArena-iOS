//
//  DeckRowView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/15/25.
//

import SwiftUI

struct DeckRowView: View {
    let deck: Deck
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // TCG Icon
            ZStack {
                Circle()
                    .fill(deck.tcgType.themeColor.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                SwiftUI.Image(systemName: deck.tcgType.systemIcon)
                    .font(.system(size: 18))
                    .foregroundColor(deck.tcgType.themeColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                // Deck Name
                Text(deck.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(TCGTheme.Colors.textPrimary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                // Description
                if let description = deck.description {
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(TCGTheme.Colors.textSecondary)
                        .lineLimit(1)
                }
                
                // Tags
                if !deck.tags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(deck.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(TCGTheme.Colors.accent)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(TCGTheme.Colors.accent.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Card count
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(deck.totalCards)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(TCGTheme.Colors.textPrimary)
                
                Text("cards")
                    .font(.system(size: 12))
                    .foregroundColor(TCGTheme.Colors.textMuted)
            }
            
            // Chevron
            SwiftUI.Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
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
}