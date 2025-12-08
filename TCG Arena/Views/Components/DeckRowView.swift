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
        ZStack(alignment: .bottomLeading) {
            // Abstract Gradient Background
            GeometryReader { geo in
                abstractBackground
                    .frame(width: geo.size.width, height: geo.size.height)
            }
            
            // Gradient Overlay for text readability
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.85),
                    Color.black.opacity(0.4),
                    Color.black.opacity(0.1)
                ]),
                startPoint: .bottom,
                endPoint: .top
            )
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    // TCG Badge
                    HStack(spacing: 4) {
                        SwiftUI.Image(systemName: deck.tcgType.systemIcon)
                            .font(.system(size: 10, weight: .bold))
                        Text(deck.tcgType.displayName)
                            .font(.system(size: 10, weight: .bold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Material.thinMaterial)
                    .clipShape(Capsule())
                    .foregroundColor(.white)
                    
                    // Deck Type Badge
                    DeckTypeBadge(deckType: deck.deckType)
                    
                    Spacer()
                    
                    // Card Count Badge
                    HStack(spacing: 4) {
                        SwiftUI.Image(systemName: "rectangle.stack.fill")
                            .font(.system(size: 10))
                        Text("\(deck.totalCards)")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Capsule())
                    .foregroundColor(.white)
                }
                
                Spacer()
                
                // Deck Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(deck.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .shadow(radius: 2)
                    
                    if let description = deck.description, !description.isEmpty {
                        Text(description)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(1)
                            .shadow(radius: 1)
                    }
                    
                    // Tags
                    if !deck.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(deck.tags.prefix(3), id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(deck.tcgType.themeColor.opacity(0.8))
                                        .cornerRadius(4)
                                }
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .frame(height: 160)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Abstract Background Design
    private var abstractBackground: some View {
        ZStack {
            // Base gradient with TCG theme colors
            LinearGradient(
                gradient: Gradient(colors: [
                    deck.tcgType.themeColor.opacity(0.8),
                    deck.tcgType.themeColor.opacity(0.4),
                    complementaryColor.opacity(0.3)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Decorative geometric shapes
            GeometryReader { geo in
                // Large circle in top-right
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                deck.tcgType.themeColor.opacity(0.6),
                                deck.tcgType.themeColor.opacity(0.1)
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: geo.size.width * 0.4
                        )
                    )
                    .frame(width: geo.size.width * 0.7, height: geo.size.width * 0.7)
                    .offset(x: geo.size.width * 0.5, y: -geo.size.height * 0.3)
                
                // Smaller circle in bottom-left
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                complementaryColor.opacity(0.4),
                                complementaryColor.opacity(0.05)
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: geo.size.width * 0.25
                        )
                    )
                    .frame(width: geo.size.width * 0.5, height: geo.size.width * 0.5)
                    .offset(x: -geo.size.width * 0.15, y: geo.size.height * 0.4)
                
                // Stylized TCG icon in center-right
                SwiftUI.Image(systemName: deck.tcgType.systemIcon)
                    .font(.system(size: 50, weight: .ultraLight))
                    .foregroundColor(.white.opacity(0.15))
                    .offset(x: geo.size.width * 0.6, y: geo.size.height * 0.3)
            }
            
            // Subtle noise/texture overlay
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.05),
                            Color.clear,
                            Color.black.opacity(0.1)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    }
    
    // Complementary color for visual interest
    private var complementaryColor: Color {
        switch deck.tcgType {
        case .pokemon:
            return Color.orange
        case .magic:
            return Color.purple
        case .yugioh:
            return Color.red
        case .onePiece:
            return Color.blue
        case .digimon:
            return Color.cyan
        case .dragonBallSuper, .dragonBallFusion:
            return Color.yellow
        case .fleshAndBlood:
            return Color.red.opacity(0.7)
        case .lorcana:
            return Color.orange
        }
    }
}
