//
//  DeckSelectionModal.swift
//  TCG Arena
//
//  Created by Antigravity AI
//

import SwiftUI

struct DeckSelectionModal: View {
    let cardName: String
    let onDeckSelected: (Deck) -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var deckService: DeckService
    
    @State private var selectedDeck: Deck? = nil
    @State private var isConfirming = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if deckService.userDecks.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            headerView
                            deckListView
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Select Deck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SwiftUI.Image(systemName: "square.stack.3d.up.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("Add to Deck")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            
            Text("Choose a deck to add '\(cardName)'")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private var deckListView: some View {
        VStack(spacing: 12) {
            ForEach(deckService.userDecks) { deck in
                DeckCardRow(
                    deck: deck,
                    isSelected: selectedDeck?.id == deck.id,
                    isConfirming: isConfirming && selectedDeck?.id == deck.id
                ) {
                    selectDeck(deck)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            SwiftUI.Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("No Decks Available")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create a deck first to add cards to it")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    private func selectDeck(_ deck: Deck) {
        if selectedDeck?.id == deck.id && !isConfirming {
            // Second tap on same deck - confirm
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isConfirming = true
            }
            
            // Auto-confirm after brief delay to show the animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                onDeckSelected(deck)
                dismiss()
            }
        } else {
            // First tap - select deck
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedDeck = deck
                isConfirming = false
            }
        }
    }
}

// MARK: - Deck Card Row
struct DeckCardRow: View {
    let deck: Deck
    let isSelected: Bool
    let isConfirming: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Deck Icon
                ZStack {
                    Circle()
                        .fill(deck.tcgType.themeColor.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    SwiftUI.Image(systemName: "square.stack.3d.up.fill")
                        .font(.title3)
                        .foregroundColor(deck.tcgType.themeColor)
                }
                
                // Deck Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(deck.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(deck.tcgType.themeColor)
                            .frame(width: 8, height: 8)
                        
                        Text(deck.tcgType.displayName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("• \(deck.cards.count) cards")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Selection Indicator
                ZStack {
                    if isConfirming {
                        SwiftUI.Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                            .transition(.scale.combined(with: .opacity))
                    } else if isSelected {
                        VStack(spacing: 4) {
                            SwiftUI.Image(systemName: "hand.tap.fill")
                                .font(.caption)
                                .foregroundColor(deck.tcgType.themeColor)
                            Text("Tap again")
                                .font(.caption2)
                                .foregroundColor(deck.tcgType.themeColor)
                        }
                        .transition(.scale.combined(with: .opacity))
                    } else {
                        SwiftUI.Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                }
                .frame(width: 60)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? deck.tcgType.themeColor.opacity(0.08) : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                isSelected ? deck.tcgType.themeColor.opacity(0.3) : Color.clear,
                                lineWidth: isSelected ? 2 : 0
                            )
                    )
                    .shadow(color: Color.black.opacity(isSelected ? 0.08 : 0.05), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
