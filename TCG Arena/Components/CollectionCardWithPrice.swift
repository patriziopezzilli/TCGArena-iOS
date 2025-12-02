import SwiftUI
import Foundation

struct CollectionCardWithPrice: View {
    let card: Card
    let marketService: MarketDataService
    let showMarketValues: Bool
    
    private var cardPrice: CardPrice? {
        // Simula il matching con ID della carta
        return marketService.getPriceForCard(card.name.lowercased().replacingOccurrences(of: " ", with: "-"))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Immagine della carta
            CachedAsyncImage(url: card.fullImageURL.flatMap { URL(string: $0) }) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .aspectRatio(2.5/3.5, contentMode: .fit)
                        .overlay(
                            SwiftUI.Image(systemName: "photo")
                                .foregroundColor(.secondary)
                        )
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                case .failure(_):
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .aspectRatio(2.5/3.5, contentMode: .fit)
                        .overlay(
                            SwiftUI.Image(systemName: "photo")
                                .foregroundColor(.secondary)
                        )
                @unknown default:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .aspectRatio(2.5/3.5, contentMode: .fit)
                        .overlay(
                            SwiftUI.Image(systemName: "photo")
                                .foregroundColor(.secondary)
                        )
                }
            }
            .aspectRatio(2.5/3.5, contentMode: .fit) // Proporzioni reali delle carte TCG
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Informazioni carta
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(card.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Badge rarità
                    Text(card.rarity.shortName)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(card.rarity.color)
                        )
                }
                
                // Set e condizione
                HStack {
                    Text(card.set ?? "Unknown")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(card.condition.shortName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Prezzo se abilitato
                if showMarketValues, let price = cardPrice {
                    Divider()
                        .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(price.formattedPrice)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            HStack(spacing: 2) {
                                SwiftUI.Image(systemName: price.weeklyChangePercent >= 0 ? "arrow.up" : "arrow.down")
                                    .font(.system(size: 10))
                                Text(price.formattedChange)
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundColor(price.priceChangeColor)
                        }
                        
                        Text("Updated \(timeAgoString(from: price.lastUpdated))")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                } else if showMarketValues {
                    Divider()
                        .padding(.vertical, 4)
                    
                    HStack {
                        Text("Price N/A")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        SwiftUI.Image(systemName: "questionmark.circle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .frame(width: 160)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AdaptiveColors.backgroundPrimary)
                .shadow(
                    color: AdaptiveColors.neutralDark.opacity(0.1),
                    radius: 10,
                    x: 0,
                    y: 4
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AdaptiveColors.neutralLight, lineWidth: 1)
        )
    }
    
    private func timeAgoString(from date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        if timeInterval < 3600 { // Less than 1 hour
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m ago"
        } else if timeInterval < 86400 { // Less than 1 day
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        } else { // 1 day or more
            let days = Int(timeInterval / 86400)
            return "\(days)d ago"
        }
    }
}