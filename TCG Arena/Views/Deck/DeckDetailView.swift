//
//  DeckDetailView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/15/25.
//

import SwiftUI

struct DeckDetailView: View {
    let deck: Deck
    @EnvironmentObject var deckService: DeckService
    @State private var selectedCard: Card? = nil
    @State private var isCardActive = false
    
    var deckCards: [Card] {
        // Mock: in realtà dovremmo avere le carte dal cardService filtrate per deckID
        // Per ora, simuliamo con carte mock
        deck.cards.map { deckCard in
            Card(
                id: deckCard.id,
                templateId: deckCard.cardId,
                name: deckCard.cardName,
                rarity: .common,
                condition: .nearMint,
                imageURL: deckCard.cardImageUrl,
                isFoil: false,
                quantity: deckCard.quantity,
                ownerId: 1,
                createdAt: Date(),
                updatedAt: Date(),
                tcgType: deck.tcgType,
                set: "Mock Set",
                cardNumber: "1/100",
                expansion: nil,
                marketPrice: nil
            )
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(deck.tcgType.themeColor.opacity(0.1))
                            .frame(width: 80, height: 80)
                        
                        SwiftUI.Image(systemName: deck.tcgType.systemIcon)
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(deck.tcgType.themeColor)
                    }
                    
                    VStack(spacing: 8) {
                        Text(deck.name)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("\(deck.totalCards) cards • \(deck.tcgType.displayName)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    if let description = deck.description {
                        Text(description)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.top, 40)
                .padding(.horizontal, 32)
                
                // Cards List
                List(deckCards) { card in
                    Button(action: { 
                        selectedCard = card
                        isCardActive = true
                    }) {
                        TCGCardView(card, deckService: deckService)
                    }
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 0))
                }
                .listStyle(PlainListStyle())
                .background(Color(.systemBackground))
            }
            .navigationTitle(deck.name)
            .navigationBarTitleDisplayMode(.inline)
            .background(
                Group {
                    if selectedCard != nil {
                        NavigationLink("", destination: CardDetailView(card: selectedCard!), isActive: Binding(get: { isCardActive }, set: { isCardActive = $0; if !$0 { selectedCard = nil } }))
                    }
                }
            )
        }
    }
}