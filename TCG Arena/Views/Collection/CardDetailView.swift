//
//  CardDetailView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/5/25.
//

import SwiftUI

struct CardDetailView: View {
    let card: Card
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var cardService: CardService
    @StateObject private var marketService = MarketDataService()
    @AppStorage("showMarketValues") private var showMarketValues = true
    @State private var showingEditView = false
    @State private var showingDeleteConfirmation = false
    
    private var cardPrice: CardPrice? {
        return marketService.getPriceForCard(card.name.lowercased().replacingOccurrences(of: " ", with: "-"))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Clean Header with TCG Icon
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(card.tcgType.themeColor)
                            .frame(width: 60, height: 60)
                        
                        SwiftUI.Image(systemName: card.tcgType.systemIcon)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(card.name)
                            .font(.system(size: UIConstants.headerFontSize, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        Text(card.tcgType.displayName)
                            .font(.system(size: UIConstants.subheaderFontSize, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // Card Details Card
                InfoCard(title: "Card Overview") {
                    HStack(spacing: 20) {
                        // Card Image
                        if let imageURL = card.imageURL, let url = URL(string: imageURL) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    RoundedRectangle(cornerRadius: UIConstants.cornerRadius)
                                        .fill(Color(.systemGray6))
                                        .frame(width: 120, height: 170)
                                        .overlay(
                                            ProgressView()
                                        )
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 120, height: 170)
                                        .clipShape(RoundedRectangle(cornerRadius: UIConstants.cornerRadius))
                                case .failure(_):
                                    RoundedRectangle(cornerRadius: UIConstants.cornerRadius)
                                        .fill(Color(.systemGray6))
                                        .frame(width: 120, height: 170)
                                        .overlay(
                                            VStack(spacing: 8) {
                                                SwiftUI.Image(systemName: card.tcgType.systemIcon)
                                                    .font(.system(size: 32, weight: .medium))
                                                    .foregroundColor(card.tcgType.themeColor.opacity(0.6))
                                                
                                                Text("Image Error")
                                                    .font(.system(size: 11, weight: .medium))
                                                    .foregroundColor(.secondary)
                                            }
                                        )
                                @unknown default:
                                    RoundedRectangle(cornerRadius: UIConstants.cornerRadius)
                                        .fill(Color(.systemGray6))
                                        .frame(width: 120, height: 170)
                                }
                            }
                        } else {
                            // Placeholder when no image URL
                            RoundedRectangle(cornerRadius: UIConstants.cornerRadius)
                                .fill(Color(.systemGray6))
                                .frame(width: 120, height: 170)
                                .overlay(
                                    VStack(spacing: 8) {
                                        SwiftUI.Image(systemName: card.tcgType.systemIcon)
                                            .font(.system(size: 32, weight: .medium))
                                            .foregroundColor(card.tcgType.themeColor.opacity(0.6))
                                        
                                        Text("Card Image")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }
                                )
                        }
                        
                        // Quick Info beside image
                        VStack(alignment: .leading, spacing: 12) {
                            InfoRow(label: "Set", value: card.set ?? "Unknown", color: .secondary)
                            InfoRow(label: "Number", value: card.cardNumber!, color: .secondary)
                            InfoRow(label: "Rarity", value: card.rarity.rawValue, color: card.rarity.color)
                            InfoRow(label: "Condition", value: card.condition.rawValue, color: card.condition.color)
                            
                            if let cardPrice = cardPrice {
                                InfoRow(label: "Price", value: "€\(String(format: "%.2f", cardPrice.currentPrice))", color: card.tcgType.themeColor)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 20)
                    
                    // Additional Information Cards
                    VStack(spacing: 20) {
                        // Grading & History Card
                        InfoCard(title: "Additional Info") {
                            VStack(spacing: 12) {
                                InfoRow(label: "Grade", value: "Ungraded", color: .secondary)
                                
                                InfoRow(label: "Added", value: card.createdAt.formatted(date: .abbreviated, time: .omitted), color: .secondary)
                            }
                        }
                        
                        // Market Value Card (se abilitato)
                        if showMarketValues {
                            InfoCard(title: "Market Value") {
                                if let price = cardPrice {
                                    VStack(spacing: 16) {
                                        // Prezzo attuale
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Current Price")
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                                
                                                Text(price.formattedPrice)
                                                    .font(.system(size: 28, weight: .bold))
                                                    .foregroundColor(.primary)
                                            }
                                            
                                            Spacer()
                                            
                                            VStack(alignment: .trailing, spacing: 4) {
                                                HStack(spacing: 4) {
                                                    SwiftUI.Image(systemName: price.weeklyChangePercent >= 0 ? "arrow.up.right" : "arrow.down.right")
                                                        .font(.caption)
                                                    Text(price.formattedChange)
                                                        .font(.subheadline)
                                                        .fontWeight(.medium)
                                                }
                                                .foregroundColor(price.priceChangeColor)
                                                
                                                Text("7 days")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        
                                        Divider()
                                        
                                        // Dettagli aggiuntivi
                                        VStack(spacing: 8) {
                                            HStack {
                                                Text("Previous Week")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                Spacer()
                                                Text(String(format: "$%.2f", price.previousPrice))
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.primary)
                                            }
                                            
                                            HStack {
                                                Text("Price Change")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                Spacer()
                                                Text(String(format: "$%.2f", price.weeklyChange))
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(price.priceChangeColor)
                                            }
                                            
                                            HStack {
                                                Text("Last Updated")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                Spacer()
                                                Text(price.lastUpdated.formatted(date: .abbreviated, time: .shortened))
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                } else {
                                    VStack(spacing: 12) {
                                        HStack {
                                            SwiftUI.Image(systemName: "chart.line.uptrend.xyaxis")
                                                .font(.title2)
                                                .foregroundColor(.secondary)
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Price Not Available")
                                                    .font(.headline)
                                                    .foregroundColor(.primary)
                                                
                                                Text("Market data for this card is currently unavailable")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            Spacer()
                                        }
                                        
                                        Button("Request Price Data") {
                                            // TODO: Richiedi dati di prezzo
                                        }
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                        
                        // Action Buttons
                    VStack(spacing: 16) {
                        Button(action: {
                            showingEditView = true
                        }) {
                            HStack {
                                SwiftUI.Image(systemName: "pencil")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Edit Card")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(card.tcgType.themeColor)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(
                                RoundedRectangle(cornerRadius: UIConstants.cornerRadius)
                                    .fill(card.tcgType.themeColor.opacity(0.1))
                            )
                        }
                        
                        Button(action: {
                            showingDeleteConfirmation = true
                        }) {
                            HStack {
                                SwiftUI.Image(systemName: "trash")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Delete Card")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(
                                RoundedRectangle(cornerRadius: UIConstants.cornerRadius)
                                    .fill(Color.red.opacity(0.1))
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
                .padding(.bottom, 32)
            }
            .navigationTitle(card.name)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingEditView) {
                EditCardView(card: card)
            }
            .alert("Delete Card", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteCard()
                }
            } message: {
                Text("Are you sure you want to delete '\(card.name)'? This action cannot be undone.")
            }
            .onAppear {
                if showMarketValues {
                    marketService.loadMarketData()
                }
            }
    }
    
    private func deleteCard() {
        // TODO: Implement delete functionality with new backend API
        // For now, show a message that this feature is being migrated
        print("Delete functionality is being migrated to new backend API")
        dismiss()
    }
    
    private var cardIconName: String {
        switch card.tcgType {
        case .pokemon: return "bolt.circle"
        case .magic: return "sparkles"
        case .yugioh: return "eye.circle"
        case .onePiece: return "sailboat"
        case .digimon: return "shield.circle"
        }
    }
}

#Preview {
    CardDetailView(card: Card(
        id: 1,
        templateId: 1,
        name: "Pikachu",
        rarity: .rare,
        condition: .nearMint,
        imageURL: nil,
        isFoil: false,
        quantity: 1,
        ownerId: 1,
        createdAt: Date(),
        updatedAt: Date(),
        tcgType: .pokemon,
        set: "Base Set",
        cardNumber: "1/102",
        expansion: nil,
        marketPrice: nil
    ))
}
