import SwiftUI

struct ProDecksListView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var deckService = DeckService()
    @State private var selectedTCGType: TCGType? = nil
    
    var filteredDecks: [ProDeck] {
        if let selectedType = selectedTCGType {
            return deckService.proDecks.filter { $0.tcgType == selectedType }
        }
        return deckService.proDecks
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Professional Decks")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("\(filteredDecks.count) decks available")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Done") {
                        dismiss()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                // TCG Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        FilterChip(
                            title: "All",
                            isSelected: selectedTCGType == nil,
                            action: { selectedTCGType = nil }
                        )
                        
                        ForEach(TCGType.allCases, id: \.self) { tcgType in
                            FilterChip(
                                title: tcgType.displayName,
                                isSelected: selectedTCGType == tcgType,
                                action: { selectedTCGType = tcgType }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 16)
                
                // Pro Decks List
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredDecks) { deck in
                            NavigationLink(destination: ProDeckListView(proDeck: deck)) {
                                ProDeckRowView(deck: deck)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
        }
    }
}

struct ProDeckRowView: View {
    let deck: ProDeck
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // TCG Icon
                ZStack {
                    Circle()
                        .fill(deck.tcgType.themeColor)
                        .frame(width: 50, height: 50)
                    
                    SwiftUI.Image(systemName: deck.tcgType.systemIcon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(deck.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text("by \(deck.author)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(deck.tournament)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Spacer()
            }
            .padding(16)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(
                    color: Color.black.opacity(0.1),
                    radius: 4,
                    x: 0,
                    y: 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(deck.tcgType.themeColor.opacity(0.3), lineWidth: 1)
        )
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.blue : Color(.systemGray6))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
    }
}