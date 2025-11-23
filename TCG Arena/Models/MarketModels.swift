import Foundation
import SwiftUI

// MARK: - Market Price Models
struct CardPrice: Identifiable, Codable {
    let id = UUID()
    let cardId: String
    let currentPrice: Double
    let previousPrice: Double
    let weeklyChange: Double
    let weeklyChangePercent: Double
    let condition: Card.CardCondition
    let rarity: Rarity
    let lastUpdated: Date
    
    enum CodingKeys: String, CodingKey {
        case cardId = "card_id"
        case currentPrice = "current_price"
        case previousPrice = "previous_price"
        case weeklyChange = "weekly_change"
        case weeklyChangePercent = "weekly_change_percent"
        case condition
        case rarity
        case lastUpdated = "last_updated"
    }
    
    var priceChangeColor: Color {
        if weeklyChangePercent > 0 {
            return .green
        } else if weeklyChangePercent < 0 {
            return .red
        } else {
            return .secondary
        }
    }
    
    var formattedPrice: String {
        return String(format: "$%.2f", currentPrice)
    }
    
    var formattedChange: String {
        let sign = weeklyChangePercent >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", weeklyChangePercent))%"
    }
}

struct PortfolioSummary: Codable {
    let totalValue: Double
    let weeklyChange: Double
    let weeklyChangePercent: Double
    let cardCount: Int
    let topGainers: [CardPrice]
    let topLosers: [CardPrice]
    let lastUpdated: Date
    
    var formattedTotalValue: String {
        if totalValue >= 1000 {
            return String(format: "$%.1fK", totalValue / 1000)
        } else {
            return String(format: "$%.0f", totalValue)
        }
    }
    
    var formattedWeeklyChange: String {
        let sign = weeklyChangePercent >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", weeklyChangePercent))%"
    }
    
    var changeColor: Color {
        if weeklyChangePercent > 0 {
            return .green
        } else if weeklyChangePercent < 0 {
            return .red
        } else {
            return .secondary
        }
    }
}

// MARK: - Market Data Service
class MarketDataService: ObservableObject {
    @Published var portfolioSummary: PortfolioSummary?
    @Published var cardPrices: [String: CardPrice] = [:]
    @Published var isLoading = false
    
    // Mock data per la demo
    func loadMarketData() {
        isLoading = true
        
        // Simula caricamento dati
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.generateMockData()
            self.isLoading = false
        }
    }
    
    private func generateMockData() {
        // Mock card prices
        let mockPrices = [
            CardPrice(
                cardId: "charizard",
                currentPrice: 450.00,
                previousPrice: 420.00,
                weeklyChange: 30.00,
                weeklyChangePercent: 7.1,
                condition: .mint,
                rarity: .rare,
                lastUpdated: Date()
            ),
            CardPrice(
                cardId: "pikachu",
                currentPrice: 125.00,
                previousPrice: 110.00,
                weeklyChange: 15.00,
                weeklyChangePercent: 13.6,
                condition: .nearMint,
                rarity: .rare,
                lastUpdated: Date()
            ),
            CardPrice(
                cardId: "black-lotus",
                currentPrice: 15000.00,
                previousPrice: 15200.00,
                weeklyChange: -200.00,
                weeklyChangePercent: -1.3,
                condition: .lightlyPlayed,
                rarity: .rare,
                lastUpdated: Date()
            ),
            CardPrice(
                cardId: "blue-eyes-white-dragon",
                currentPrice: 89.99,
                previousPrice: 85.00,
                weeklyChange: 4.99,
                weeklyChangePercent: 5.9,
                condition: .nearMint,
                rarity: .rare,
                lastUpdated: Date()
            ),
            CardPrice(
                cardId: "mox-ruby",
                currentPrice: 3200.00,
                previousPrice: 3100.00,
                weeklyChange: 100.00,
                weeklyChangePercent: 3.2,
                condition: .mint,
                rarity: .rare,
                lastUpdated: Date()
            ),
            CardPrice(
                cardId: "monkey-d-luffy",
                currentPrice: 45.99,
                previousPrice: 52.00,
                weeklyChange: -6.01,
                weeklyChangePercent: -11.6,
                condition: .nearMint,
                rarity: .uncommon,
                lastUpdated: Date()
            )
        ]
        
        // Popola il dizionario dei prezzi
        for price in mockPrices {
            cardPrices[price.cardId] = price
        }
        
        // Mock portfolio summary
        let totalValue = mockPrices.reduce(0) { $0 + $1.currentPrice }
        let totalWeeklyChange = mockPrices.reduce(0) { $0 + $1.weeklyChange }
        
        // Calcola la percentuale di cambio
        let weeklyChangePercent = (totalWeeklyChange / (totalValue - totalWeeklyChange)) * 100
        
        // Filtra e ordina i guadagni
        let gainers = mockPrices.filter { $0.weeklyChangePercent > 0 }
        let sortedGainers = gainers.sorted { $0.weeklyChangePercent > $1.weeklyChangePercent }
        let topGainers = Array(sortedGainers.prefix(3))
        
        // Filtra e ordina le perdite
        let losers = mockPrices.filter { $0.weeklyChangePercent < 0 }
        let sortedLosers = losers.sorted { $0.weeklyChangePercent < $1.weeklyChangePercent }
        let topLosers = Array(sortedLosers.prefix(2))
        
        portfolioSummary = PortfolioSummary(
            totalValue: totalValue,
            weeklyChange: totalWeeklyChange,
            weeklyChangePercent: weeklyChangePercent,
            cardCount: mockPrices.count,
            topGainers: topGainers,
            topLosers: topLosers,
            lastUpdated: Date()
        )
    }
    
    func getPriceForCard(_ cardId: String) -> CardPrice? {
        return cardPrices[cardId]
    }
}