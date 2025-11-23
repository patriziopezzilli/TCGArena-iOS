import SwiftUI

// MARK: - SimpleProCardDetailView (simplified card detail for pro decks)
struct SimpleProCardDetailView: View {
    let deckCard: ProDeckCard
    @StateObject private var marketService = MarketDataService()
    @AppStorage("showMarketValues") private var showMarketValues = true
    
    private var cardPrice: CardPrice? {
        return marketService.getPriceForCard(deckCard.cardTemplate.name.lowercased().replacingOccurrences(of: " ", with: "-"))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Card Image Placeholder
                RoundedRectangle(cornerRadius: 16)
                    .fill(deckCard.cardTemplate.tcgType.themeColor.opacity(0.2))
                    .frame(height: 400)
                    .overlay(
                        VStack(spacing: 16) {
                            SwiftUI.Image(systemName: deckCard.cardTemplate.tcgType.systemIcon)
                                .font(.system(size: 80, weight: .semibold))
                                .foregroundColor(deckCard.cardTemplate.tcgType.themeColor)
                            
                            Text(deckCard.cardTemplate.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    )
                    .padding(.horizontal, 20)
                
                // Card Details
                VStack(alignment: .leading, spacing: 16) {
                    // Set & Number
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Set")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(deckCard.cardTemplate.setCode)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Number")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(deckCard.cardTemplate.cardNumber)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                    
                    // Rarity
                    HStack {
                        Text("Rarity")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(deckCard.cardTemplate.rarity.rawValue)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(deckCard.cardTemplate.rarity.color)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                    
                    // Quantity in deck
                    HStack {
                        Text("Quantity in Deck")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(deckCard.quantity)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(deckCard.cardTemplate.tcgType.themeColor)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(deckCard.cardTemplate.tcgType.themeColor.opacity(0.1))
                    )
                    
                    // Market Price
                    if showMarketValues, let price = cardPrice {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Market Value")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack(alignment: .bottom) {
                                Text(price.formattedPrice)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                                
                                Text("per card")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.bottom, 4)
                                
                                Spacer()
                                
                                if deckCard.quantity > 1 {
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("Total (\(deckCard.quantity)x)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(String(format: "$%.2f", price.currentPrice * Double(deckCard.quantity)))
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                    }
                    
                    // Description
                    if let description = deckCard.cardTemplate.description, !description.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)
                            
                            Text(description)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 32)
        }
        .navigationTitle(deckCard.cardTemplate.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if showMarketValues {
                marketService.loadMarketData()
            }
        }
    }
}
