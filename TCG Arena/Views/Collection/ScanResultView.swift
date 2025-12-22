
import SwiftUI

struct ScanResultView: View {
    let scannedTokens: [String]
    @Environment(\.dismiss) private var dismiss
    @StateObject private var cardService = CardService.shared
    @StateObject private var deckService = DeckService.shared
    
    @State private var isLoading = true
    @State private var matchedCards: [CardTemplate] = []
    @State private var selectedDeck: Deck?
    @State private var isAdding = false
    @State private var showSuccessMessage = false
    @State private var animateLoader = false
    
    @State private var filterText = ""
    
    var filteredCards: [CardTemplate] {
        if filterText.isEmpty {
            return matchedCards
        } else {
            return matchedCards.filter { card in
                let nameMatch = card.name.localizedCaseInsensitiveContains(filterText)
                let numberMatch = (card.cardNumber ?? "").localizedCaseInsensitiveContains(filterText)
                let setMatch = (card.setCode ?? "").localizedCaseInsensitiveContains(filterText)
                return nameMatch || numberMatch || setMatch
            }
        }
    }
    
    // Grid layout for suggestions
    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 120), spacing: 16)
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    VStack(spacing: 24) {
                        // Cool Animated Loader
                        ZStack {
                            Circle()
                                .stroke(lineWidth: 4)
                                .foregroundColor(Color.blue.opacity(0.3))
                                .frame(width: 80, height: 80)
                            
                            Circle()
                                .trim(from: 0.0, to: 0.7)
                                .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .foregroundColor(.blue)
                                .frame(width: 80, height: 80)
                                .rotationEffect(Angle(degrees: animateLoader ? 360 : 0))
                                .onAppear {
                                    withAnimation(Animation.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                                        animateLoader = true
                                    }
                                }
                        }
                        
                        Text("Analyzing Intelligence...")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        // Display detected tokens in a "Matrix" or "Tag Cloud" style
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(scannedTokens, id: \.self) { token in
                                    Text(token)
                                        .font(.system(.caption, design: .monospaced))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                        )
                                        .cornerRadius(8)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(height: 40)
                    }
                    .padding()
                } else if matchedCards.isEmpty {
                    VStack(spacing: 16) {
                        // ... Empty State ...
                        SwiftUI.Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("No matches found")
                            .font(.headline)
                        Text("Try scanning again or add manually.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else if matchedCards.count == 1 && filterText.isEmpty, let card = matchedCards.first {
                    // Single Match (only if not filtering)
                    SingleMatchView(card: card, selectedDeck: $selectedDeck, isAdding: isAdding, availableDecks: availableDecks(for: card)) {
                        addToDeck(card: card)
                    }
                } else {
                    // Multiple Matches - "Suggestions" UI
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Found \(matchedCards.count) possible matches")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        // Filter Bar
                        HStack {
                            SwiftUI.Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Filter by number (e.g. 58) or name", text: $filterText)
                                .textFieldStyle(PlainTextFieldStyle())
                            if !filterText.isEmpty {
                                Button(action: { filterText = "" }) {
                                    SwiftUI.Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 20) {
                                ForEach(filteredCards) { card in
                                    Button(action: {
                                        // Select this card
                                        matchedCards = [card]
                                        filterText = "" // Clear filter to show SingleMatchView
                                    }) {
                                        VStack {
                                            AsyncImage(url: URL(string: card.imageUrl ?? "")) { image in
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                            } placeholder: {
                                                Rectangle()
                                                    .fill(Color.gray.opacity(0.2))
                                                    .overlay(ProgressView())
                                            }
                                            .frame(height: 150)
                                            .cornerRadius(8)
                                            
                                            Text(card.name)
                                                .font(.caption)
                                                .lineLimit(1)
                                                .foregroundColor(.primary)
                                            Text(card.cardNumber ?? "")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Scan Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Chiudi") { dismiss() }
                }
            }
        }
        .onAppear {
            performSearch()
            deckService.loadUserDecks(userId: AuthService.shared.currentUserId ?? 0) { _ in }
        }
        .alert("Added Successfully!", isPresented: $showSuccessMessage) {
            Button("OK") { dismiss() }
        }
    }
    
    private func performSearch() {
        isLoading = true
        // Use the smart search from CardService
        cardService.smartScan(rawTexts: scannedTokens) { result in
            print("DEBUG: ScanResultView - Searching with tokens: \(scannedTokens)") 
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let cards):
                    print("DEBUG: ScanResultView - Search success. Found \(cards.count) cards.")
                    self.matchedCards = cards
                    // Pre-select the matching deck if there's only one logical choice?
                    // Not strictly necessary, user should choose.
                case .failure(let error):
                    print("DEBUG: ScanResultView - Search failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func availableDecks(for card: CardTemplate) -> [Deck] {
        // Filter decks by compatible TCG Type or default to Pokemon if nil (or show all if we want lenient)
        // Since TCGType is optional in model but essential for logic, we unwrap or default
        if let type = card.tcgType {
             return deckService.userDecks.filter { $0.tcgType == type }
        }
        return [] // Or return all? Safe to return empty if unknown type.
    }
    
    private func addToDeck(card: CardTemplate) {
        guard let deck = selectedDeck, let deckId = deck.id else { return }
        
        isAdding = true
        deckService.addCardTemplateToDeck(deckId: deckId, templateId: Int64(card.id), userId: AuthService.shared.currentUserId ?? 0) { result in
            DispatchQueue.main.async {
                isAdding = false
                switch result {
                case .success:
                    showSuccessMessage = true
                    // Haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                case .failure(let error):
                    print("Failed to add card: \(error.localizedDescription)")
                    // Show error alert (omitted for brevity)
                }
            }
        }
    }
}

struct SingleMatchView: View {
    let card: CardTemplate
    @Binding var selectedDeck: Deck?
    let isAdding: Bool
    let availableDecks: [Deck]
    let onAdd: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Card Image
                AsyncImage(url: URL(string: card.imageUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .overlay(SwiftUI.Image(systemName: "photo").font(.largeTitle).foregroundColor(.gray))
                }
                .frame(height: 350)
                .cornerRadius(16)
                .shadow(radius: 10)
                
                // Info
                VStack(spacing: 8) {
                    Text(card.name)
                        .font(.title2)
                        .bold()
                    
                    HStack {
                        Text((card.setCode ?? "").uppercased())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                        
                        Text(card.cardNumber ?? "")
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                // Add to Deck Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Add to Collection/Deck")
                        .font(.headline)
                    
                    if availableDecks.isEmpty {
                        Text("No compatible decks found for \(card.tcgType?.displayName ?? "Unknown TCG"). Create one first!")
                            .foregroundColor(.red)
                            .font(.caption)
                    } else {
                        Picker("Select Deck", selection: Binding(
                            get: { selectedDeck?.name ?? "" },
                            set: { name in selectedDeck = availableDecks.first(where: { $0.name == name }) }
                        )) {
                            Text("Select a Deck").tag("")
                            ForEach(availableDecks, id: \.name) { deck in
                                Text(deck.name).tag(deck.name)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    Button(action: onAdd) {
                        HStack {
                            if isAdding {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Add Card")
                                    .bold()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedDeck == nil || isAdding ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(selectedDeck == nil || isAdding)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 5)
            }
            .padding()
        }
    }
}
