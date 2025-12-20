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
        HStack(spacing: 16) {
            deckIconView
            
            VStack(alignment: .leading, spacing: 4) {
                Text(deck.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                
                HStack(spacing: 6) {
                    Text("\(deck.totalCards) Carte")
                    
                    Text("•")
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text(deck.tcgType.displayName)
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            SwiftUI.Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator).opacity(0.4), lineWidth: 0.5)
        )
        // subtle shadow for depth in the list, consistent with ShopCardView if needed, or kept flat
        .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
    }
    
    private var deckIconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(deck.tcgType.themeColor.opacity(0.08))
                .frame(width: 48, height: 48)
            
            SwiftUI.Image(systemName: deck.deckType == .deck ? "rectangle.portrait.on.rectangle.portrait.fill" : "folder.fill")
                .font(.system(size: 20))
                .foregroundColor(deck.tcgType.themeColor)
        }
    }
}
