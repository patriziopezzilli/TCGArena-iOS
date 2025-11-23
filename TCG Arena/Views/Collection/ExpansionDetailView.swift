//
//  ExpansionDetailView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/10/25.
//

import SwiftUI

struct ExpansionDetailView: View {
    let expansion: Expansion
    @StateObject private var expansionService = ExpansionService()
    @Environment(\.presentationMode) var presentationMode
    @State private var cards: [CardTemplate] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Section
                    expansionHeaderSection
                    
                    // Sets Section
                    expansionSetsSection
                    
                    // Cards Section
                    cardsSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color(.systemBackground))
            .navigationTitle(expansion.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .task {
            await loadCards()
        }
    }
    
    // MARK: - Header Section
    private var expansionHeaderSection: some View {
        VStack(spacing: 16) {
            // Expansion Image
            AsyncImage(url: URL(string: expansion.imageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                RoundedRectangle(cornerRadius: 16)
                    .fill(expansion.tcgType.themeColor.opacity(0.2))
                    .overlay(
                        VStack(spacing: 8) {
                            SwiftUI.Image(systemName: expansion.tcgType.systemIcon)
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(expansion.tcgType.themeColor)
                            
                            Text(expansion.title)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(expansion.tcgType.themeColor)
                                .multilineTextAlignment(.center)
                        }
                    )
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: expansion.tcgType.themeColor.opacity(0.3), radius: 8, x: 0, y: 4)
            
            // Expansion Info
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(expansion.title)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 8) {
                            Circle()
                                .fill(expansion.tcgType.themeColor)
                                .frame(width: 8, height: 8)
                            
                            Text(expansion.tcgType.displayName)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(expansion.tcgType.themeColor)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Released")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text(expansion.sets.first?.formattedReleaseDate ?? "Unknown")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
            )
        }
    }
    
    // MARK: - Sets Section
    private var expansionSetsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sets in this Expansion")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            
            ForEach(expansion.sets) { set in
                SetDetailCard(set: set)
            }
        }
    }
    
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            SwiftUI.Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Cards Section
    private var cardsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Featured Cards")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            
            if cards.isEmpty && !isLoading {
                emptyCardsView
            } else {
                // Group cards by set - temporarily disabled due to SwiftUI binding issue
                Text("Cards section coming soon")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 20)
            }
        }
    }
    
    private var emptyCardsView: some View {
        VStack(spacing: 16) {
            SwiftUI.Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 40, weight: .medium))
                .foregroundColor(.secondary)
            
            Text("No cards available")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Actions
    private func loadCards() async {
        isLoading = true
        cards = await expansionService.loadCards(for: expansion)
        isLoading = false
    }
}

// MARK: - Expansion Card View
struct ExpansionCardView: View {
    let card: Card
    
    var body: some View {
        VStack(spacing: 12) {
            // Card Image
            AsyncImage(url: URL(string: card.imageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 12)
                    .fill(card.tcgType.themeColor.opacity(0.2))
                    .overlay(
                        VStack(spacing: 4) {
                            SwiftUI.Image(systemName: card.tcgType.systemIcon)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(card.tcgType.themeColor)
                            
                            Text(card.cardNumber ?? "N/A")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(card.tcgType.themeColor)
                        }
                    )
            }
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Card Info
            VStack(spacing: 6) {
                Text(card.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                Text(card.rarity.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(rarityColor(card.rarity))
                
                if let price = card.marketPrice {
                    Text("$\(price, specifier: "%.2f")")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.green)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
    
    private func rarityColor(_ rarity: Rarity) -> Color {
        switch rarity {
        case .common: return .secondary
        case .uncommon: return .green
        case .rare: return .blue
        case .ultraRare: return .purple
        case .secretRare: return .orange
        case .holographic: return .cyan
        case .promo: return .mint
        case .mythic: return .yellow
        case .legendary: return .pink
        }
    }
}

// MARK: - Set Detail Card Component
struct SetDetailCard: View {
    let set: TCGSet
    
    private var cardColor: Color {
        let hash = abs(set.setCode.hashValue)
        let hue = Double(hash % 360) / 360.0
        return Color(hue: hue, saturation: 0.6, brightness: 0.8)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Set Image/Icon
            ZStack {
                AsyncImage(url: URL(string: set.imageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(cardColor.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .overlay(
                            SwiftUI.Image(systemName: "square.stack.3d.up.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(cardColor)
                        )
                }
            }
            
            // Set Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(set.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(set.setCode.uppercased())
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(cardColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(cardColor.opacity(0.1))
                        .clipShape(Capsule())
                }
                
                if let description = set.description {
                    Text(description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        SwiftUI.Image(systemName: "square.stack.3d.up.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Text("\(set.cardCount) cards")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        SwiftUI.Image(systemName: "calendar")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Text(set.formattedReleaseDate)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: cardColor.opacity(0.2), radius: 6, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(cardColor.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    let mockExpansion = Expansion(
        id: 1,
        title: "Mock Expansion",
        tcgType: .magic,
        imageUrl: nil,
        sets: []
    )
    ExpansionDetailView(expansion: mockExpansion)
}