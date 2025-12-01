import SwiftUI
import Foundation

struct ProDeckListView: View {
    let proDeck: ProDeck
    @Environment(\.dismiss) private var dismiss
    @StateObject private var marketService = MarketDataService()
    @AppStorage("showMarketValues") private var showMarketValues: Bool = true
    @State private var selectedTab = 0
    @State private var selectedCard: ProDeckCard? = nil
    @State private var isCardActive = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Pro Deck Header
            ProDeckListHeader(proDeck: proDeck)
            
            // Tabs
            Picker("View", selection: $selectedTab) {
                Text("Mainboard (\(proDeck.totalMainboardCards))").tag(0)
                if !proDeck.sideboard.isEmpty {
                    Text("Sideboard (\(proDeck.sideboard.count))").tag(1)
                }
                Text("Strategy").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            // Content
            TabView(selection: $selectedTab) {
                // Mainboard
                DeckCardListView(
                    cards: proDeck.cards ?? [],
                    marketService: marketService,
                    showMarketValues: showMarketValues,
                    onSelect: {
                        selectedCard = $0
                        isCardActive = true
                    }
                )
                .tag(0)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AdaptiveColors.backgroundPrimary)
                        .shadow(
                            color: AdaptiveColors.neutralDark.opacity(0.1),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                )
                
                // Sideboard
                if !proDeck.sideboard.isEmpty {
                    DeckCardListView(
                        cards: proDeck.sideboard,
                        marketService: marketService,
                        showMarketValues: showMarketValues,
                        onSelect: {
                            selectedCard = $0
                            isCardActive = true
                        }
                    )
                    .tag(1)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AdaptiveColors.backgroundPrimary)
                            .shadow(
                                color: AdaptiveColors.neutralDark.opacity(0.1),
                                radius: 8,
                                x: 0,
                                y: 4
                            )
                    )
                }
                
                // Strategy
                ProDeckStrategyView(proDeck: proDeck)
                    .tag(2)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AdaptiveColors.backgroundPrimary)
                            .shadow(
                                color: AdaptiveColors.neutralDark.opacity(0.1),
                                radius: 8,
                                x: 0,
                                y: 4
                            )
                    )
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .padding(.horizontal, 24) // Adjusted padding for modern spacing
            .padding(.top, 20) // Increased top padding for better alignment
        }
        .navigationTitle(proDeck.name)
        .navigationBarTitleDisplayMode(.inline)
        .background(
            Group {
                if selectedCard != nil {
                    NavigationLink("", destination: SimpleProCardDetailView(deckCard: selectedCard!), isActive: Binding(get: { isCardActive }, set: { isCardActive = $0; if !$0 { selectedCard = nil } }))
                }
            }
        )
        .onAppear {
            if showMarketValues {
                marketService.loadMarketData()
            }
        }
    }
}

struct ProDeckListHeader: View {
    let proDeck: ProDeck
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                // TCG Icon
                ZStack {
                    Circle()
                        .fill(proDeck.tcgType.themeColor)
                        .frame(width: 50, height: 50)
                    
                    SwiftUI.Image(systemName: proDeck.tcgType.systemIcon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(proDeck.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("by \(proDeck.author)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(proDeck.totalMainboardCards)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("cards")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Tournament Info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    SwiftUI.Image(systemName: "trophy.fill")
                        .foregroundColor(.yellow)
                    
                    Text(proDeck.tournament)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(proDeck.placement)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                HStack {
                    SwiftUI.Image(systemName: "calendar")
                        .foregroundColor(.blue)
                    
                    Text(proDeck.createdAt.formatted(.dateTime.month().day().year()))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal, 20)
    }
}

struct ProDeckStatPill: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.1))
        )
    }
}

struct ProDeckStrategyView: View {
    let proDeck: ProDeck
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Description
                VStack(alignment: .leading, spacing: 12) {
                    Text("Deck Overview")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(proDeck.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                // Strategy
                VStack(alignment: .leading, spacing: 12) {
                    Text("Strategy Guide")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(proDeck.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                // Key Cards
                if !proDeck.keyCards.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Key Cards")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        ForEach(proDeck.keyCards, id: \.self) { cardName in
                            HStack {
                                Circle()
                                    .fill(proDeck.tcgType.themeColor)
                                    .frame(width: 8, height: 8)
                                
                                Text(cardName)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                        }
                    }
                }
                
                // Performance Tips
                VStack(alignment: .leading, spacing: 12) {
                    Text("Performance Tips")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        TipRow(
                            icon: "lightbulb.fill",
                            text: "Mulligan aggressively for your key early game pieces",
                            color: .yellow
                        )
                        
                        TipRow(
                            icon: "target",
                            text: "Focus on your win condition and don't get distracted",
                            color: .red
                        )
                        
                        TipRow(
                            icon: "clock.fill",
                            text: "Average game time: 25 minutes",
                            color: .blue
                        )
                        
                        TipRow(
                            icon: "chart.line.uptrend.xyaxis",
                            text: "This deck performs well in the current meta",
                            color: .green
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            SwiftUI.Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}
