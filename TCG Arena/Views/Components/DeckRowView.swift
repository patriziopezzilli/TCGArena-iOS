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
            deckInfoView
            
            Spacer()
            
            SwiftUI.Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
                
                RoundedRectangle(cornerRadius: 16)
                    .fill(deck.tcgType.themeColor.opacity(0.02))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(deck.tcgType.themeColor.opacity(0.2), lineWidth: 1.5)
        )
    }
    
    private var deckIconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(deck.tcgType.themeColor.opacity(0.1))
                .frame(width: 60, height: 60)
            
            SwiftUI.Image(systemName: deck.deckType == .deck ? "rectangle.stack.fill" : "folder.fill")
                .font(.system(size: 24))
                .foregroundColor(deck.tcgType.themeColor)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(deck.tcgType.themeColor.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var deckInfoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(deck.name)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)
            
            if let description = deck.description, !description.isEmpty {
                Text(description)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            HStack(spacing: 8) {
                TCGIconView(tcgType: deck.tcgType, size: 12, color: deck.tcgType.themeColor)
                
                Text("\(deck.totalCards) carte")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }
}
