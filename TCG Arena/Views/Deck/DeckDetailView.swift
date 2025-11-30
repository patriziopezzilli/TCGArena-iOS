import SwiftUI

struct DeckDetailView: View {
    let deck: Deck
    @EnvironmentObject var deckService: DeckService
    @Environment(\.presentationMode) var presentationMode
    
    // Computed property for cover image
    private var coverImageUrl: String? {
        // Find the first card with an image
        if let firstCardWithImage = deck.cards.first(where: { $0.cardImageUrl != nil }) {
            var url = firstCardWithImage.cardImageUrl
            if let imageUrl = url, !imageUrl.contains("/high.webp") {
                return "\(imageUrl)/high.webp"
            }
            return url
        }
        return nil
    }
    
    var deckCards: [Card] {
        // Mock: in realtà dovremmo avere le carte dal cardService filtrate per deckID
        // Per ora, simuliamo con carte mock
        deck.cards.compactMap { deckCard in
            // Assicuriamoci che i dati essenziali siano presenti
            guard let cardId = deckCard.id else {
                print("⚠️ DeckDetailView: Skipping invalid deck card - missing id")
                return nil
            }
            
            // Fix image URL if needed
            var imageUrl = deckCard.cardImageUrl
            if let url = imageUrl, !url.contains("/high.webp") {
                imageUrl = "\(url)/high.webp"
            }
            
            return Card(
                id: cardId,
                templateId: deckCard.cardId,
                name: deckCard.cardName,
                rarity: .common,
                condition: .nearMint,
                imageURL: imageUrl,
                isFoil: false,
                quantity: deckCard.quantity,
                ownerId: 1,
                createdAt: Date(),
                updatedAt: Date(),
                tcgType: deck.tcgType,
                set: "Mock Set",
                cardNumber: "1/100",
                expansion: nil,
                marketPrice: nil,
                description: nil
            )
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Fixed Header
            ZStack(alignment: .bottomLeading) {
                // Background Image
                GeometryReader { geometry in
                    if let imageUrl = coverImageUrl {
                        CachedAsyncImage(url: URL(string: imageUrl)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                                    .clipped()
                            case .failure, .empty:
                                fallbackHeaderBackground
                            @unknown default:
                                fallbackHeaderBackground
                            }
                        }
                    } else {
                        fallbackHeaderBackground
                    }
                }
                
                // Gradient Overlay
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.9),
                        Color.black.opacity(0.5),
                        Color.clear
                    ]),
                    startPoint: .bottom,
                    endPoint: .top
                )
                
                // Header Content
                VStack(alignment: .leading, spacing: 8) {
                    // Badges
                    HStack(spacing: 8) {
                        // TCG Badge
                        HStack(spacing: 4) {
                            SwiftUI.Image(systemName: deck.tcgType.systemIcon)
                                .font(.system(size: 12, weight: .bold))
                            Text(deck.tcgType.displayName)
                                .font(.system(size: 12, weight: .bold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Material.thinMaterial)
                        .clipShape(Capsule())
                        .foregroundColor(.white)
                        
                        // Card Count Badge
                        HStack(spacing: 4) {
                            SwiftUI.Image(systemName: "rectangle.stack.fill")
                                .font(.system(size: 12))
                            Text("\(deck.totalCards) cards")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Capsule())
                        .foregroundColor(.white)
                    }
                    
                    Text(deck.name)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(radius: 4)
                    
                    if let description = deck.description, !description.isEmpty {
                        Text(description)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(2)
                            .shadow(radius: 2)
                    }
                }
                .padding(20)
            }
            .frame(height: 250)
            .clipped()
            .overlay(
                // Custom Back Button
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Circle()
                        .fill(Color.black.opacity(0.5))
                        .frame(width: 32, height: 32)
                        .overlay(
                            SwiftUI.Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
                .padding(.leading, 16)
                .padding(.top, 60), // Increased padding to avoid Dynamic Island
                alignment: .topLeading
            )
            
            // Scrollable Content
            List {
                if deckCards.isEmpty {
                    emptyStateView
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(deckCards) { card in
                        ZStack {
                            NavigationLink(destination: CardDetailView(card: card, isFromDiscover: false)) {
                                EmptyView()
                            }
                            .opacity(0)
                            
                            CardRowView(card: card, deckService: deckService)
                        }
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .listStyle(PlainListStyle())
            .background(Color(.systemGroupedBackground))
        }
        .navigationBarHidden(true)
        .edgesIgnoringSafeArea(.top)
    }
    
    private var fallbackHeaderBackground: some View {
        ZStack {
            deck.tcgType.themeColor.opacity(0.3)
            
            SwiftUI.Image(systemName: deck.tcgType.systemIcon)
                .font(.system(size: 80))
                .foregroundColor(deck.tcgType.themeColor.opacity(0.5))
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(height: 40)
            
            ZStack {
                Circle()
                    .fill(deck.tcgType.themeColor.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                SwiftUI.Image(systemName: "rectangle.portrait.on.rectangle.portrait.slash")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(deck.tcgType.themeColor)
            }
            
            VStack(spacing: 8) {
                Text("No Cards Yet")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("This deck is empty. Add cards from the search or scan them to build your deck.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: {
                // TODO: Navigate to add card view
            }) {
                HStack(spacing: 8) {
                    SwiftUI.Image(systemName: "plus")
                    Text("Add Cards")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(deck.tcgType.themeColor)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            Spacer()
        }
    }
}
