import SwiftUI

struct DeckDetailView: View {
    let deck: Deck
    @EnvironmentObject var deckService: DeckService
    @EnvironmentObject var authService: AuthService
    @Environment(\.presentationMode) var presentationMode
    @State private var deckCards: [Card] = []
    @State private var isLoadingCards = false
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var editName = ""
    @State private var editDescription = ""
    @State private var isUpdating = false
    @State private var isDeleting = false
    
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
    
    private func loadDeckCards() {
        isLoadingCards = true
        deckCards = []
        
        // Convert deck cards to basic Card objects and enrich with template data
        let group = DispatchGroup()
        let serialQueue = DispatchQueue(label: "com.tcgarena.deckCardEnrichment")
        var enrichedCards: [Card] = []
        
        for deckCard in deck.cards {
            group.enter()
            // Create basic card from deck card
            let basicCard = convertDeckCardToCard(deckCard)
            
            // Enrich with template data
            CardService.shared.enrichCardWithTemplateData(basicCard) { result in
                serialQueue.async {
                    switch result {
                    case .success(let enrichedCard):
                        enrichedCards.append(enrichedCard)
                    case .failure(let error):
                        print("Failed to enrich card \(deckCard.cardName): \(error.localizedDescription)")
                        // Use basic card if enrichment fails
                        enrichedCards.append(basicCard)
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            // Sort cards by name for consistent ordering
            serialQueue.sync {
                self.deckCards = enrichedCards.sorted { $0.name < $1.name }
            }
            self.isLoadingCards = false
        }
    }
    
    private func convertDeckCardToCard(_ deckCard: Deck.DeckCard) -> Card {
        return Card(
            id: deckCard.id,
            templateId: deckCard.cardId,
            name: deckCard.cardName,
            rarity: .common, // Will be updated from template
            condition: deckCard.condition ?? .nearMint,
            imageURL: deckCard.cardImageUrl,
            isFoil: false,
            quantity: deckCard.quantity,
            ownerId: 1, // Will be updated from auth
            createdAt: Date(),
            updatedAt: Date(),
            tcgType: deck.tcgType,
            set: nil, // Will be updated from template
            cardNumber: nil, // Will be updated from template
            expansion: nil,
            marketPrice: nil,
            description: nil,
            // Copy grading information from deck card
            isGraded: deckCard.isGraded,
            gradingCompany: deckCard.gradingCompany,
            grade: deckCard.grade,
            certificateNumber: deckCard.certificateNumber
        )
    }
    
    var body: some View {
        GeometryReader { geometry in
            let safeAreaTop = geometry.safeAreaInsets.top
            
            ZStack(alignment: .top) {
                // Fixed Header
                ZStack(alignment: .bottomLeading) {
                    // Abstract Gradient Background
                    abstractHeaderBackground
                        .frame(width: geometry.size.width, height: 280 + safeAreaTop)
                    
                    // Gradient Overlay
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.85),
                            Color.black.opacity(0.5),
                            Color.black.opacity(0.3)
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
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .padding(.top, safeAreaTop + 50) // Spazio dinamico per Dynamic Island
            }
            .frame(height: 280 + safeAreaTop) // Altezza dinamica
            .frame(maxWidth: .infinity)
            .ignoresSafeArea(edges: .top)
            .overlay(
                // Custom Back Button and Menu
                HStack {
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
                    
                    Spacer()
                    
                    Menu {
                        Button(action: {
                            editName = deck.name
                            editDescription = deck.description ?? ""
                            showingEditSheet = true
                        }) {
                            Label("Edit Deck", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive, action: {
                            print("🗑️ Delete button tapped")
                            showingDeleteAlert = true
                        }) {
                            Label("Delete Deck", systemImage: "trash")
                        }
                    } label: {
                        Circle()
                            .fill(Color.black.opacity(0.5))
                            .frame(width: 32, height: 32)
                            .overlay(
                                SwiftUI.Image(systemName: "ellipsis")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, safeAreaTop + 8), // Padding dinamico per Dynamic Island
                alignment: .topLeading
            )
            
            // Scrollable Content
            List {
                if isLoadingCards {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 40)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                } else if deckCards.isEmpty {
                    emptyStateView
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    ForEach(deckCards) { card in
                        ZStack {
                            NavigationLink(destination: CardDetailView(card: card, isFromDiscover: false, deckId: deck.id) { updatedCard in
                                // Update the card in the local deck cards array
                                if let index = deckCards.firstIndex(where: { $0.id == updatedCard.id }) {
                                    deckCards[index] = updatedCard
                                }
                                // Also refresh deck data from service
                                loadDeckCards()
                            }) {
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
            .padding(.top, 270 + safeAreaTop) // Match header height
        }
        }
        .navigationBarHidden(true)
        .confirmationDialog("Delete Deck", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                deleteDeck()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete \"\(deck.name)\"? This action cannot be undone.")
        }
        .sheet(isPresented: $showingEditSheet) {
            EditDeckView(
                deck: deck,
                name: $editName,
                description: $editDescription,
                isUpdating: $isUpdating,
                onSave: updateDeck
            )
        }
        .onAppear {
            loadDeckCards()
        }
    }
    
    // MARK: - Abstract Header Background
    private var abstractHeaderBackground: some View {
        ZStack {
            // Base gradient with TCG theme colors
            LinearGradient(
                gradient: Gradient(colors: [
                    deck.tcgType.themeColor.opacity(0.8),
                    deck.tcgType.themeColor.opacity(0.4),
                    complementaryColor.opacity(0.3)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Decorative geometric shapes
            GeometryReader { geo in
                // Large circle in top-right
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                deck.tcgType.themeColor.opacity(0.6),
                                deck.tcgType.themeColor.opacity(0.1)
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: geo.size.width * 0.4
                        )
                    )
                    .frame(width: geo.size.width * 0.7, height: geo.size.width * 0.7)
                    .offset(x: geo.size.width * 0.5, y: -geo.size.height * 0.2)
                
                // Smaller circle in bottom-left
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                complementaryColor.opacity(0.4),
                                complementaryColor.opacity(0.05)
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: geo.size.width * 0.3
                        )
                    )
                    .frame(width: geo.size.width * 0.6, height: geo.size.width * 0.6)
                    .offset(x: -geo.size.width * 0.2, y: geo.size.height * 0.5)
                
                // Stylized TCG icon in center-right
                SwiftUI.Image(systemName: deck.tcgType.systemIcon)
                    .font(.system(size: 80, weight: .ultraLight))
                    .foregroundColor(.white.opacity(0.12))
                    .offset(x: geo.size.width * 0.55, y: geo.size.height * 0.35)
            }
            
            // Subtle overlay for depth
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.05),
                            Color.clear,
                            Color.black.opacity(0.1)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    }
    
    // Complementary color for visual interest
    private var complementaryColor: Color {
        switch deck.tcgType {
        case .pokemon:
            return Color.orange
        case .magic:
            return Color.purple
        case .yugioh:
            return Color.red
        case .onePiece:
            return Color.blue
        case .digimon:
            return Color.cyan
        case .dragonBallSuper:
            return Color.yellow
        case .dragonBallFusion:
            return Color.green
        case .fleshAndBlood:
            return Color.red.opacity(0.7)
        case .lorcana:
            return Color.gray
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
            
            // Temporarily hide Add Cards button until functionality is implemented
            /*
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
            */
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    private func updateDeck() {
        guard let deckId = deck.id else { return }
        
        isUpdating = true
        
        deckService.updateDeck(
            id: deckId,
            name: editName.trimmingCharacters(in: .whitespacesAndNewlines),
            description: editDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : editDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            userId: deck.ownerId
        ) { result in
            DispatchQueue.main.async {
                isUpdating = false
                switch result {
                case .success:
                    // Close the edit sheet and return to homepage
                    showingEditSheet = false
                    presentationMode.wrappedValue.dismiss()
                case .failure(let error):
                    if case APIError.unauthorized = error {
                        ToastManager.shared.showError("Your session has expired. Please log in again.")
                    } else {
                        ToastManager.shared.showError("Unable to update deck. Please check your connection and try again.")
                    }
                }
            }
        }
    }
    
    private func deleteDeck() {
        guard let deckId = deck.id else { return }
        
        isDeleting = true
        
        deckService.deleteDeck(deckId: deckId, userId: deck.ownerId) { result in
            DispatchQueue.main.async {
                isDeleting = false
                switch result {
                case .success:
                    presentationMode.wrappedValue.dismiss()
                case .failure(let error):
                    if case APIError.unauthorized = error {
                        ToastManager.shared.showError("Your session has expired. Please log in again.")
                    } else {
                        ToastManager.shared.showError("Unable to delete deck. Please check your connection and try again.")
                    }
                }
            }
        }
    }
}

// MARK: - Edit Deck View
struct EditDeckView: View {
    let deck: Deck
    @Binding var name: String
    @Binding var description: String
    @Binding var isUpdating: Bool
    let onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [deck.tcgType.themeColor, deck.tcgType.themeColor.opacity(0.7)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 60, height: 60)
                            
                            SwiftUI.Image(systemName: "pencil")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 4) {
                            Text("Edit Deck")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("Update your deck information")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 16)
                    
                    // Deck Information Section
                    VStack(spacing: 16) {
                        SectionHeaderView(title: "Deck Information", subtitle: "Name and description")
                        
                        VStack(spacing: 16) {
                            // Deck Name
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Deck Name")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                TextField("Enter deck name", text: $name)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.systemGray6))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color(.systemGray4), lineWidth: 1)
                                    )
                            }
                            
                            // Description
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description (Optional)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                ZStack(alignment: .topLeading) {
                                    if description.isEmpty {
                                        Text("Describe your deck strategy, playstyle, or key cards...")
                                            .foregroundColor(.secondary)
                                            .padding(.top, 12)
                                            .padding(.leading, 16)
                                            .font(.system(size: 15))
                                    }
                                    
                                    TextEditor(text: $description)
                                        .frame(minHeight: 100)
                                        .padding(12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color(.systemGray6))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color(.systemGray4), lineWidth: 1)
                                        )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Save Button
                    LoadingButton(
                        title: "Save Changes",
                        loadingTitle: "Updating Deck...",
                        isLoading: isUpdating,
                        isDisabled: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                        color: deck.tcgType.themeColor,
                        action: onSave
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Edit Deck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if isUpdating {
                    LoadingOverlay(message: "Updating your deck...")
                }
            }
            .withToastSupport()
        }
    }
}
