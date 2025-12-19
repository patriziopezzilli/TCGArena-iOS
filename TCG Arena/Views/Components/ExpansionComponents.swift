//
//  ExpansionComponents.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/10/25.
//

import SwiftUI

// MARK: - Expansion Card Component
struct ExpansionCard: View {
    let expansion: Expansion
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Expansion Image
                AsyncImage(url: URL(string: expansion.sets.first(where: { $0.logoUrl != nil })?.logoUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(expansion.tcgType.themeColor.opacity(0.2))
                        .overlay(
                            VStack(spacing: 6) {
                                TCGIconView(tcgType: expansion.tcgType, size: 28, color: expansion.tcgType.themeColor)
                                
                                Text("\(expansion.sets.count) set\(expansion.sets.count == 1 ? "" : "s")")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(expansion.tcgType.themeColor)
                            }
                        )
                }
                .frame(height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Recent Cards Preview
                let allCards: [CardTemplate] = expansion.sets.compactMap { $0.cards }.flatMap { $0 }
                let recentCards = Array(allCards.prefix(5))
                
                if !recentCards.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(recentCards) { card in
                            AsyncImage(url: URL(string: card.fullImageUrl ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            } placeholder: {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(
                                        SwiftUI.Image(systemName: "photo")
                                            .font(.system(size: 8))
                                            .foregroundColor(.gray)
                                    )
                            }
                            .frame(width: 20, height: 28)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                    .frame(height: 32)
                }
                
                // Expansion Info
                VStack(spacing: 4) {
                    Text(expansion.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(expansion.tcgType.themeColor)
                            .frame(width: 6, height: 6)
                        
                        Text(expansion.tcgType.displayName)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(expansion.tcgType.themeColor)
                    }
                    
                    Text(expansion.formattedReleaseDate)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(expansion.tcgType.themeColor.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Expansion Row Component (for lists)
struct ExpansionRow: View {
    let expansion: Expansion
    let showCards: Bool
    let isButton: Bool
    let action: () -> Void
    
    init(expansion: Expansion, showCards: Bool = true, isButton: Bool = true, action: @escaping () -> Void) {
        self.expansion = expansion
        self.showCards = showCards
        self.isButton = isButton
        self.action = action
    }
    
    var body: some View {
        content
            .conditionalButton(isButton: isButton, action: action)
    }
    
    private var content: some View {
        HStack(spacing: 16) {
            // Expansion Image
            AsyncImage(url: URL(string: expansion.imageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(expansion.tcgType.themeColor.opacity(0.2))
                    .overlay(
                        TCGIconView(tcgType: expansion.tcgType, size: 20, color: expansion.tcgType.themeColor)
                        )
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Expansion Details
            VStack(alignment: .leading, spacing: 6) {
                Text(expansion.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Circle()
                        .fill(expansion.tcgType.themeColor)
                        .frame(width: 8, height: 8)
                    
                    Text(expansion.tcgType.displayName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(expansion.tcgType.themeColor)
                }
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        SwiftUI.Image(systemName: "square.stack.3d.up.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        
                        Text("\(expansion.cardCount) cards")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Arrow indicator
            SwiftUI.Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Recent Expansions Carousel
struct RecentExpansionsCarousel: View {
    let expansions: [Expansion]
    let onExpansionTap: (Expansion) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recent Expansions")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Discover the latest card sets")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(expansions) { expansion in
                        ExpansionCard(expansion: expansion) {
                            onExpansionTap(expansion)
                        }
                        .frame(width: 160)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Expansion Badge (small indicator)
struct ExpansionBadge: View {
    let expansion: Expansion
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                TCGIconView(tcgType: expansion.tcgType, size: 10, color: expansion.tcgType.themeColor)
                
                Text(expansion.title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if !expansion.sets.isEmpty {
                    Text("(\(expansion.sets.map { $0.name }.joined(separator: ", ")))")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(expansion.tcgType.themeColor.opacity(0.05))
                    .overlay(
                        Capsule()
                            .stroke(expansion.tcgType.themeColor.opacity(0.2), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - View Extensions
extension View {
    @ViewBuilder
    func conditionalButton(isButton: Bool, action: @escaping () -> Void) -> some View {
        if isButton {
            Button(action: action) {
                self
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            self
        }
    }
}