import SwiftUI
import Foundation

struct PortfolioCard: View {
    let portfolio: PortfolioSummary
    @State private var showingDetail = false
    @State private var isExpanded = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Header con titolo e valore totale - Cliccabile per espandere/collassare
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("Portfolio Value")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            SwiftUI.Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .rotationEffect(.degrees(isExpanded ? 0 : -90))
                                .animation(.easeInOut(duration: 0.3), value: isExpanded)
                        }
                        
                        Text(portfolio.formattedTotalValue)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 4) {
                            SwiftUI.Image(systemName: portfolio.weeklyChangePercent >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.caption)
                            Text(portfolio.formattedWeeklyChange)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(portfolio.changeColor)
                        
                        Text("This Week")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, isExpanded ? 0 : 20)
            
            // Sezioni collassabili
            if isExpanded {
                // Statistiche rapide
                HStack(spacing: 12) {
                    StatPill(
                        title: "Cards",
                        value: "\(portfolio.cardCount)",
                        color: .blue
                    )
                    .frame(maxWidth: .infinity)
                    
                    StatPill(
                        title: "Avg. Value",
                        value: String(format: "$%.0f", portfolio.totalValue / Double(portfolio.cardCount)),
                        color: .orange
                    )
                    .frame(maxWidth: .infinity)
                    
                    StatPill(
                        title: "Top Gain",
                        value: portfolio.topGainers.first?.formattedChange ?? "0%",
                        color: .green
                    )
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                // Grafico placeholder (miniatura)
                HStack {
                    Text("Market Trend")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    
                    // Mini chart placeholder
                    HStack(spacing: 2) {
                        ForEach(0..<7) { index in
                            Rectangle()
                                .fill(portfolio.changeColor.opacity(0.6))
                                .frame(width: 3, height: CGFloat.random(in: 8...20))
                                .cornerRadius(1.5)
                        }
                    }
                    
                    Button("View Details") {
                        showingDetail = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 20)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(
                    color: Color.black.opacity(0.06),
                    radius: 12,
                    x: 0,
                    y: 4
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray6), lineWidth: 1)
        )
        .sheet(isPresented: $showingDetail) {
            PortfolioDetailView(portfolio: portfolio)
        }
    }
}

struct StatPill: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(height: 44)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
}

struct PortfolioDetailView: View {
    let portfolio: PortfolioSummary
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header con valore totale
                    VStack(spacing: 8) {
                        Text("Total Portfolio Value")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        Text(String(format: "$%.2f", portfolio.totalValue))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 8) {
                            SwiftUI.Image(systemName: portfolio.weeklyChangePercent >= 0 ? "arrow.up.right" : "arrow.down.right")
                            Text("\(portfolio.formattedWeeklyChange) this week")
                                .font(.title3)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(portfolio.changeColor)
                    }
                    .padding(.top, 20)
                    
                    // Performance cards
                    if !portfolio.topGainers.isEmpty || !portfolio.topLosers.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Performance Highlights")
                                .font(.headline)
                                .padding(.horizontal, 20)
                            
                            if !portfolio.topGainers.isEmpty {
                                PerformanceSection(
                                    title: "Top Gainers",
                                    cards: portfolio.topGainers,
                                    isPositive: true
                                )
                            }
                            
                            if !portfolio.topLosers.isEmpty {
                                PerformanceSection(
                                    title: "Biggest Declines",
                                    cards: portfolio.topLosers,
                                    isPositive: false
                                )
                            }
                        }
                    }
                    
                    // Breakdown per condizione
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Value Breakdown")
                            .font(.headline)
                            .padding(.horizontal, 20)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            BreakdownCard(
                                title: "Mint Condition",
                                value: "$1,245",
                                percentage: "44%",
                                color: .green
                            )
                            
                            BreakdownCard(
                                title: "Near Mint",
                                value: "$967",
                                percentage: "34%",
                                color: .blue
                            )
                            
                            BreakdownCard(
                                title: "Light Play",
                                value: "$456",
                                percentage: "16%",
                                color: .orange
                            )
                            
                            BreakdownCard(
                                title: "Other",
                                value: "$179",
                                percentage: "6%",
                                color: .purple
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 32)
            }
            .navigationTitle("Portfolio Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct PerformanceSection: View {
    let title: String
    let cards: [CardPrice]
    let isPositive: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(cards) { card in
                        PerformanceCard(card: card, isPositive: isPositive)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

struct PerformanceCard: View {
    let card: CardPrice
    let isPositive: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(card.formattedPrice)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text(card.formattedChange)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(card.priceChangeColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(card.priceChangeColor.opacity(0.15))
                    .cornerRadius(4)
            }
            
            Text("Charizard Base Set") // Mock name
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(2)
            
            Text("\(card.condition.displayName) • \(card.rarity.rawValue)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .frame(width: 140)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
}

struct BreakdownCard: View {
    let title: String
    let value: String
    let percentage: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(percentage)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemBackground))
                .shadow(
                    color: Color.black.opacity(0.04),
                    radius: 4,
                    x: 0,
                    y: 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray6), lineWidth: 1)
        )
    }
}